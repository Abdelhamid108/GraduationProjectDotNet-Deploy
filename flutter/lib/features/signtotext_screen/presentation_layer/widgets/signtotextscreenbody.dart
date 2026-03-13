import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:graduationproject/core/style/app_assets.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:graduationproject/core/widgets/sqaure_button.dart';

List<CameraDescription> globalCameras = [];

class Signtotextscreenview extends StatefulWidget {
  const Signtotextscreenview({super.key});

  @override
  State<Signtotextscreenview> createState() => _SigntotextscreenviewState();
}

class _SigntotextscreenviewState extends State<Signtotextscreenview> {
  // --- Camera ---
  CameraController? _cameraController;
  Timer? _frameProcessingTimer;
  bool _isStreaming = false;
  bool _isProcessingFrame = false;

  // --- SignalR ---
  HubConnection? _hubConnection;
  bool _isConnected = false;
  bool _isReconnecting = false;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;

  final String _serverUrl = "https://ema2a.mooo.com/signHub";
  final String _apiBaseUrl = "https://ema2a.mooo.com";

  // --- App State ---
  String _detectionText = "جاري الاتصال...";
  String _currentWord = "";
  String _currentSentence = "";
  String _lastPrediction = "";
  int _lastPredictionTime = 0;
  final int cooldownMs = 1000;

  bool _isLoadingFinalize = false;
  bool _isLoadingAudio = false;

  final List<String> arabicLabels = [
    "ع","ال","ا","ب","د","ظ","ض","ف","ق","غ",
    "ه","ح","ج","ك","خ","لا","ل","م","ن","ر",
    "ص","س","ش","ت","ط","ث","ذ","ة","و","ئ","ي","ز"
  ];

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _initializeSignalR();
  }

  // ============================================================
  // 1. SignalR
  // ============================================================
  Future<void> _initializeSignalR() async {
    _hubConnection = HubConnectionBuilder()
        .withUrl(_serverUrl)
        .withAutomaticReconnect(retryDelays: [2000, 3000, 5000, 10000, 15000])
        .build();

    _hubConnection?.on("ReceiveTranslation", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final String message = arguments[0].toString();
        debugPrint("==== Server sent: '$message' ====");
        if (!mounted) return;

        setState(() => _detectionText = message.isEmpty
            ? 'لم يتم اكتشاف إشارة (حاول تعديل اليد)'
            : message);

        if (arabicLabels.contains(message)) {
          final int now = DateTime.now().millisecondsSinceEpoch;
          if (message != _lastPrediction ||
              (now - _lastPredictionTime) > cooldownMs) {
            setState(() {
              _currentWord += message;
              _lastPrediction = message;
              _lastPredictionTime = now;
            });
          }
        }
      }
    });

    _hubConnection?.onreconnecting(({error}) {
      debugPrint("SignalR reconnecting... $error");
      if (!mounted) return;
      setState(() {
        _isConnected = false;
        _isReconnecting = true;
        _detectionText = "جاري إعادة الاتصال...";
      });
      _frameProcessingTimer?.cancel();
    });

    _hubConnection?.onreconnected(({connectionId}) {
      debugPrint("SignalR reconnected: $connectionId");
      _reconnectAttempts = 0;
      if (!mounted) return;
      setState(() {
        _isConnected = true;
        _isReconnecting = false;
        _detectionText = _isStreaming
            ? "الكاميرا تعمل، يتم اكتشاف الحروف..."
            : "تم الاتصال. شغلي الكاميرا";
      });
      if (_isStreaming) _startFrameCapture();
    });

    _hubConnection?.onclose(({error}) {
      debugPrint("SignalR closed: $error");
      if (!mounted) return;
      setState(() {
        _isConnected = false;
        _isReconnecting = false;
        _detectionText = "انقطع الاتصال";
      });
      _frameProcessingTimer?.cancel();
      if (_reconnectAttempts < _maxReconnectAttempts) {
        _scheduleManualReconnect();
      }
    });

    await _connectToHub();
  }

  Future<void> _connectToHub() async {
    try {
      await _hubConnection?.start();
      if (!mounted) return;
      setState(() {
        _isConnected = true;
        _isReconnecting = false;
        _detectionText = "تم الاتصال. شغلي الكاميرا";
      });
      debugPrint("SignalR connected ✅");
    } catch (e) {
      debugPrint("SignalR connection failed: $e");
      if (!mounted) return;
      setState(() {
        _isConnected = false;
        _detectionText = "فشل الاتصال، جاري المحاولة...";
      });
      _scheduleManualReconnect();
    }
  }

  void _scheduleManualReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      if (mounted) {
        setState(() => _detectionText = "تعذر الاتصال بالسيرفر.");
        _showSnackBar("تعذر الاتصال بعد $_maxReconnectAttempts محاولات", Colors.red);
      }
      return;
    }
    _reconnectAttempts++;
    final int delay = _reconnectAttempts * 3;
    debugPrint("Manual reconnect attempt $_reconnectAttempts in ${delay}s");
    Future.delayed(Duration(seconds: delay), () {
      if (mounted && !_isConnected && !_isReconnecting) _connectToHub();
    });
  }

  // ============================================================
  // 2. Camera
  // ============================================================
  Future<void> _startCamera() async {
    if (!_isConnected) {
      _showSnackBar("غير متصل بالسيرفر. انتظر...", Colors.orange);
      return;
    }

    if (globalCameras.isEmpty) {
      try {
        globalCameras = await availableCameras();
      } catch (e) {
        _showSnackBar("خطأ في تحميل الكاميرات", Colors.red);
        return;
      }
    }

    if (globalCameras.isEmpty) return;

    final CameraDescription frontCamera = globalCameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => globalCameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _cameraController?.initialize();
    } catch (e) {
      _showSnackBar("فشل تشغيل الكاميرا", Colors.red);
      return;
    }

    if (!mounted) return;
    setState(() {
      _isStreaming = true;
      _detectionText = "الكاميرا تعمل، يتم اكتشاف الحروف...";
    });

    _startFrameCapture();
  }

  // ============================================================
  // 3. Frame Capture
  // ============================================================
  void _startFrameCapture() {
    _frameProcessingTimer?.cancel();
    _frameProcessingTimer = Timer.periodic(
      const Duration(milliseconds: 800),
      (timer) async {
        if (!_isConnected ||
            _hubConnection?.state != HubConnectionState.Connected ||
            _isProcessingFrame ||
            _cameraController == null ||
            !_cameraController!.value.isInitialized) return;

        _isProcessingFrame = true;
        try {
          final XFile imageFile = await _cameraController!.takePicture();
          final List<int> rawBytes = await imageFile.readAsBytes();
          final List<int> compressedBytes = await _compressImage(rawBytes);
          final String base64Image = base64Encode(compressedBytes);

          debugPrint("✅ Sending frame (${(compressedBytes.length / 1024).toStringAsFixed(1)} KB)");

          await _hubConnection!.invoke(
            "ProcessFrame",
            args: [{"ImageData": "data:image/jpeg;base64,$base64Image"}],
          ).timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint("⚠️ Frame send timeout");
              return null;
            },
          );
        } catch (e) {
          debugPrint("❌ Error capturing or sending frame: $e");
          if (e.toString().contains("Connection") ||
              e.toString().contains("closed")) {
            _frameProcessingTimer?.cancel();
            if (mounted) {
              setState(() => _detectionText = "انقطع الاتصال، جاري إعادة الاتصال...");
            }
          }
        } finally {
          _isProcessingFrame = false;
        }
      },
    );
  }

  Future<List<int>> _compressImage(List<int> rawBytes) async {
    try {
      final img.Image? image = img.decodeImage(Uint8List.fromList(rawBytes));
      if (image == null) return rawBytes;
      final img.Image resized = img.copyResize(image, width: 320, height: 240);
      return img.encodeJpg(resized, quality: 70);
    } catch (e) {
      debugPrint("Compression failed, using original: $e");
      return rawBytes;
    }
  }

  void _stopCamera() {
    _frameProcessingTimer?.cancel();
    _cameraController?.dispose();
    _cameraController = null;
    if (mounted) {
      setState(() {
        _isStreaming = false;
        _isProcessingFrame = false;
        _detectionText = _isConnected ? "تم الاتصال. شغلي الكاميرا" : "غير متصل";
      });
    }
  }

  // ============================================================
  // 4. Actions
  // ============================================================
  void _newWord() {
    if (_currentWord.isNotEmpty) {
      setState(() {
        _currentSentence += _currentWord;
        _currentWord = '';
        _lastPrediction = '';
        _lastPredictionTime = 0;
      });
    }
  }

  void _newSentence() {
    setState(() {
      _currentWord = '';
      _currentSentence = '';
      _lastPrediction = '';
      _lastPredictionTime = 0;
    });
  }

  Future<void> _correctSentence() async {
    final String textToSend =
        _currentSentence.isNotEmpty ? _currentSentence : _currentWord;
    if (textToSend.isEmpty) {
      _showSnackBar("لا يوجد نص للتصحيح", Colors.orange);
      return;
    }
    setState(() => _isLoadingFinalize = true);
    try {
      final response = await http.post(
        Uri.parse("$_apiBaseUrl/api/signlanguagetranslator/finalize-sentence"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"sentence": textToSend}),
      ).timeout(const Duration(seconds: 10));

      final result = jsonDecode(response.body);
      if (result['success'] == true && result['data'] != null) {
        setState(() => _currentSentence = result['data']);
        _showSnackBar("تم تصحيح الجملة!", Colors.green);
      } else {
        _showSnackBar(result['errorMessage'] ?? "خطأ في التصحيح", Colors.red);
      }
    } on TimeoutException {
      _showSnackBar("انتهت مهلة الطلب. حاول مرة أخرى.", Colors.red);
    } catch (e) {
      _showSnackBar("خطأ في الشبكة", Colors.red);
    } finally {
      setState(() => _isLoadingFinalize = false);
    }
  }

  Future<void> _generateAudio() async {
    final String textToSend =
        _currentSentence.isNotEmpty ? _currentSentence : _currentWord;
    if (textToSend.isEmpty) {
      _showSnackBar("لا يوجد نص لإنشاء الصوت", Colors.orange);
      return;
    }
    setState(() => _isLoadingAudio = true);
    try {
      final response = await http.post(
        Uri.parse("$_apiBaseUrl/api/signlanguagetranslator/generate-audio"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"text": textToSend}),
      ).timeout(const Duration(seconds: 15));

      final result = jsonDecode(response.body);
      if (result['success'] == true) {
        final String base64Audio = result['data']['audioData'];
        final int sampleRate = result['data']['sampleRate'];
        final Uint8List pcmBytes = base64Decode(base64Audio);
        final Uint8List wavBytes = addWavHeader(pcmBytes, sampleRate);

        final Directory tempDir = await getTemporaryDirectory();
        final String fileName =
            'audio_${DateTime.now().millisecondsSinceEpoch}.wav';
        final File tempFile = File('${tempDir.path}/$fileName');
        await tempFile.writeAsBytes(wavBytes);
        await _audioPlayer.play(DeviceFileSource(tempFile.path));
        _showSnackBar("جاري تشغيل الصوت", Colors.green);
      } else {
        _showSnackBar(result['errorMessage'] ?? "فشل إنشاء الصوت", Colors.red);
      }
    } on TimeoutException {
      _showSnackBar("انتهت مهلة الطلب", Colors.red);
    } catch (e) {
      _showSnackBar("خطأ في الصوت", Colors.red);
    } finally {
      setState(() => _isLoadingAudio = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _frameProcessingTimer?.cancel();
    _cameraController?.dispose();
    _hubConnection?.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ============================================================
  // UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'إشارة إلى نص',
          style: TextStyle(
            color: const Color(0xFF2BBBFA),
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Camera Preview ──
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 262.h,
                  margin:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.r),
                    color: Colors.black12,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _isStreaming &&
                          _cameraController != null &&
                          _cameraController!.value.isInitialized
                      ? Transform.scale(
                          scaleX: -1,
                          child: CameraPreview(_cameraController!))
                      : Center(
                          child: SvgPicture.asset(
                            AppAssets.Camera,
                            width: 60.w,
                            height: 60.h,
                          )),
                ),
                if (_isStreaming)
                  Positioned.fill(
                    child: Container(
                      margin: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                    ),
                  ),
              ],
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  SizedBox(height: 8.h),

                  // ── Connection Status ──
                  Row(
                    children: [
                      Container(
                        width: 10.w,
                        height: 10.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isReconnecting
                              ? Colors.orange
                              : (_isConnected ? Colors.green : Colors.red),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        _isReconnecting
                            ? 'جاري إعادة الاتصال...'
                            : (_isConnected ? 'متصل' : 'غير متصل'),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: _isReconnecting
                              ? Colors.orange
                              : (_isConnected ? Colors.green : Colors.red),
                        ),
                      ),
                      if (_isReconnecting)
                        Padding(
                          padding: EdgeInsets.only(right: 6.w),
                          child: SizedBox(
                            width: 12.w,
                            height: 12.h,
                            child: const CircularProgressIndicator(
                                strokeWidth: 2),
                          ),
                        ),
                      const Spacer(),
                      if (!_isConnected && !_isReconnecting)
                        TextButton(
                          onPressed: () {
                            _reconnectAttempts = 0;
                            _connectToHub();
                          },
                          child: Text(
                            "إعادة الاتصال",
                            style: TextStyle(
                                fontSize: 11.sp, color: Colors.blue),
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: 8.h),

                  // ── Camera Button ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomButton(
                        buttonText:
                            _isStreaming ? 'أوقف الكاميرا' : 'شغل الكاميرا',
                        width: 140.w,
                        height: 39.h,
                        borderRadius: 19.r,
                        buttonColor: _isStreaming
                            ? Colors.grey
                            : const Color(0xFF30BBF9),
                        onPress: _isStreaming
                            ? _stopCamera
                            : (_isConnected ? _startCamera : null),
                      ),
                      if (_isStreaming)
                        Flexible(
                          child: Padding(
                            padding: EdgeInsets.only(right: 8.w),
                            child: Text(
                              'الكاميرا قيد التشغيل، يتم اكتشاف الحروف...',
                              style: TextStyle(
                                color: const Color(0xFF5DBBFF),
                                fontSize: 12.sp,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // ── Detection Box ──
                  _infoBox(value: _detectionText, hasBorder: false),

                  SizedBox(height: 12.h),

                  // ── Current Word ──
                  _infoBox(
                    label: 'الحرف / الكلمة المكونة:',
                    value: _currentWord.isEmpty ? '' : _currentWord,
                  ),

                  SizedBox(height: 12.h),

                  // ── Current Sentence ──
                  _infoBox(
                    label: 'الجملة المكونة:',
                    value: _currentSentence.isEmpty
                        ? '(لا يوجد)'
                        : _currentSentence,
                  ),

                  SizedBox(height: 20.h),

                  // ── Action Buttons ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomButton(
                        buttonText: 'كلمة جديدة',
                        onPress: _newWord,
                      ),
                      CustomButton(
                        buttonText: 'جملة جديدة',
                        onPress: _newSentence,
                      ),
                      CustomButton(
                        buttonText: _isLoadingFinalize ? '...' : 'صحح الجملة',
                        onPress: _isLoadingFinalize ? null : _correctSentence,
                      ),
                      CustomButton(
                        buttonText: _isLoadingAudio ? '...' : 'إنشاء الصوت',
                        onPress: _isLoadingAudio ? null : _generateAudio,
                      ),
                    ],
                  ),

                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Info Box Widget ──
  Widget _infoBox({
    String? label,
    required String value,
    bool hasBorder = true,
  }) {
    return Container(
      width: double.infinity,
      height: 56.h,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: hasBorder ? const Color(0xFF5DBBFF) : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(35.r),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (label != null)
            Positioned(
              right: 16.w,
              top: 0,
              child: Text(
                label,
                style: TextStyle(
                  color: const Color(0xFF005C99),
                  fontSize: 12.sp,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  shadows: const [
                    Shadow(
                      offset: Offset(0, 4),
                      blurRadius: 4,
                      color: Color(0x40000000),
                    )
                  ],
                ),
              ),
            ),
          Positioned(
            right: 16.w,
            top: label != null ? 20.h : 0,
            bottom: 0,
            child: Center(
              child: Text(
                value,
                style: TextStyle(
                  color: const Color(0xFF005C99),
                  fontSize: label != null ? 16.sp : 13.sp,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── WAV Header ──
Uint8List addWavHeader(Uint8List pcmData, int sampleRate) {
  const int channels = 1;
  final int byteRate = sampleRate * channels * 2;
  final header = ByteData(44);
  header.setUint32(0, 0x52494646, Endian.big);
  header.setUint32(4, 36 + pcmData.length, Endian.little);
  header.setUint32(8, 0x57415645, Endian.big);
  header.setUint32(12, 0x666d7420, Endian.big);
  header.setUint32(16, 16, Endian.little);
  header.setUint16(20, 1, Endian.little);
  header.setUint16(22, channels, Endian.little);
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, byteRate, Endian.little);
  header.setUint16(32, channels * 2, Endian.little);
  header.setUint16(34, 16, Endian.little);
  header.setUint32(36, 0x64617461, Endian.big);
  header.setUint32(40, pcmData.length, Endian.little);
  final wavBytes = BytesBuilder();
  wavBytes.add(header.buffer.asUint8List());
  wavBytes.add(pcmData);
  return wavBytes.toBytes();
}