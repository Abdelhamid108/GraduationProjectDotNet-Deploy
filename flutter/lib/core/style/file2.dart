import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

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
  String _statusMessage = "Initializing...";
  String _currentLetter = "—";
  String _accumulatedLetters = "";
  String _finalSentence = "—";

  String _lastPrediction = "";
  int _lastPredictionTime = 0;
  final int cooldownMs = 1000;

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

    // استقبال الترجمة
    _hubConnection?.on("ReceiveTranslation", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final String message = arguments[0].toString();
        debugPrint("==== Server sent: '$message' ====");
        if (!mounted) return;
        setState(() => _currentLetter = message);
        if (arabicLabels.contains(message)) {
          final int now = DateTime.now().millisecondsSinceEpoch;
          if (message != _lastPrediction || (now - _lastPredictionTime) > cooldownMs) {
            setState(() {
              _accumulatedLetters += message;
              _lastPrediction = message;
              _lastPredictionTime = now;
            });
          }
        }
      }
    });

    // إعادة الاتصال
    _hubConnection?.onreconnecting(({error}) {
      debugPrint("SignalR reconnecting... $error");
      if (!mounted) return;
      setState(() {
        _isConnected = false;
        _isReconnecting = true;
        _statusMessage = "Reconnecting to server...";
      });
      // أوقف الإرسال أثناء إعادة الاتصال
      _frameProcessingTimer?.cancel();
    });

    _hubConnection?.onreconnected(({connectionId}) {
      debugPrint("SignalR reconnected: $connectionId");
      _reconnectAttempts = 0;
      if (!mounted) return;
      setState(() {
        _isConnected = true;
        _isReconnecting = false;
        _statusMessage = _isStreaming ? "Webcam active, sending frames..." : "Connected to server";
      });
      // استأنف الإرسال بعد إعادة الاتصال
      if (_isStreaming) _startFrameCapture();
    });

    _hubConnection?.onclose(({error}) {
      debugPrint("SignalR closed: $error");
      if (!mounted) return;
      setState(() {
        _isConnected = false;
        _isReconnecting = false;
        _statusMessage = "Disconnected from server";
      });
      _frameProcessingTimer?.cancel();
      // حاول الاتصال يدويًا لو فشل auto-reconnect
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
        _statusMessage = "Connected to server";
      });
      debugPrint("SignalR connected ✅");
    } catch (e) {
      debugPrint("SignalR connection failed: $e");
      if (!mounted) return;
      setState(() {
        _isConnected = false;
        _statusMessage = "Connection failed. Retrying...";
      });
      _scheduleManualReconnect();
    }
  }

  void _scheduleManualReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      if (mounted) {
        setState(() => _statusMessage = "Cannot connect to server. Check your internet.");
        _showSnackBar("Server unreachable after $_maxReconnectAttempts attempts", Colors.red);
      }
      return;
    }
    _reconnectAttempts++;
    final int delay = _reconnectAttempts * 3; // 3, 6, 9, 12, 15 ثانية
    debugPrint("Manual reconnect attempt $_reconnectAttempts in ${delay}s");
    Future.delayed(Duration(seconds: delay), () {
      if (mounted && !_isConnected && !_isReconnecting) {
        _connectToHub();
      }
    });
  }

  // ============================================================
  // 2. Camera
  // ============================================================
  Future<void> _startCamera() async {
    if (!_isConnected) {
      _showSnackBar("Not connected to server. Please wait...", Colors.orange);
      return;
    }

    if (globalCameras.isEmpty) {
      try {
        globalCameras = await availableCameras();
      } catch (e) {
        _showSnackBar("Error loading cameras", Colors.red);
        return;
      }
    }

    if (globalCameras.isEmpty) return;

    final CameraDescription frontCamera = globalCameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => globalCameras.first,
    );

    // استخدام low للتقليل من حجم الصورة المرسلة
    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _cameraController?.initialize();
    } catch (e) {
      _showSnackBar("Camera initialization failed", Colors.red);
      return;
    }

    if (!mounted) return;
    setState(() {
      _isStreaming = true;
      _statusMessage = "Webcam active, sending frames...";
    });

    _startFrameCapture();
  }

  // ============================================================
  // 3. Frame Capture - مع ضغط الصورة
  // ============================================================
  void _startFrameCapture() {
    _frameProcessingTimer?.cancel();
    // إرسال فريم كل 800ms بدل 500ms لتقليل الضغط على السيرفر
    _frameProcessingTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) async {
      // تحقق من الاتصال قبل كل إرسال
      if (!_isConnected ||
          _hubConnection?.state != HubConnectionState.Connected ||
          _isProcessingFrame ||
          _cameraController == null ||
          !_cameraController!.value.isInitialized) {
        return;
      }

      _isProcessingFrame = true;

      try {
        final XFile imageFile = await _cameraController!.takePicture();
        final List<int> rawBytes = await imageFile.readAsBytes();

        // ضغط الصورة لتقليل حجمها قبل الإرسال
        final List<int> compressedBytes = await _compressImage(rawBytes);

        final String base64Image = base64Encode(compressedBytes);
        final Map<String, String> frameDataMap = {
          "ImageData": "data:image/jpeg;base64,$base64Image"
        };

        debugPrint("✅ Sending frame (${(compressedBytes.length / 1024).toStringAsFixed(1)} KB)");

        await _hubConnection!.invoke(
          "ProcessFrame",
          args: [frameDataMap],
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint("⚠️ Frame send timeout");
            return null;
          },
        );
      } catch (e) {
        debugPrint("❌ Error capturing or sending frame: $e");
        // لو في خطأ في الاتصال، أوقف التايمر مؤقتًا
        if (e.toString().contains("Connection") || e.toString().contains("closed")) {
          _frameProcessingTimer?.cancel();
          if (mounted) setState(() => _statusMessage = "Connection lost, reconnecting...");
        }
      } finally {
        _isProcessingFrame = false;
      }
    });
  }

  // ضغط الصورة لتقليل الحجم
  Future<List<int>> _compressImage(List<int> rawBytes) async {
    try {
      final img.Image? image = img.decodeImage(Uint8List.fromList(rawBytes));
      if (image == null) return rawBytes;
      // تصغير الأبعاد لـ 320x240 وضغط الجودة لـ 70%
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
        _statusMessage = _isConnected ? "Connected to server" : "Disconnected";
        _currentLetter = "—";
      });
    }
  }

  // ============================================================
  // 4. Finalize Sentence
  // ============================================================
  Future<void> _finalizeSentence() async {
    if (_accumulatedLetters.isEmpty) {
      _showSnackBar("No letters accumulated yet.", Colors.orange);
      return;
    }
    setState(() => _finalSentence = "Processing...");
    try {
      final response = await http.post(
        Uri.parse("$_apiBaseUrl/api/signlanguagetranslator/finalize-sentence"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"sentence": _accumulatedLetters}),
      ).timeout(const Duration(seconds: 10));

      final result = jsonDecode(response.body);
      if (result['success'] == true) {
        setState(() => _finalSentence = result['data']);
        _showSnackBar("Sentence finalized!", Colors.green);
      } else {
        setState(() => _finalSentence = "—");
        _showSnackBar(result['errorMessage'] ?? "Finalize error", Colors.red);
      }
    } on TimeoutException {
      setState(() => _finalSentence = "—");
      _showSnackBar("Request timed out. Try again.", Colors.red);
    } catch (e) {
      setState(() => _finalSentence = "—");
      _showSnackBar("Network error: Failed to call API", Colors.red);
    }
  }

  // ============================================================
  // 5. Generate Sound
  // ============================================================
  Future<void> _generateSound() async {
    if (_finalSentence == "—" || _finalSentence.isEmpty || _finalSentence == "Processing...") {
      _showSnackBar("Please finalize the sentence first.", Colors.orange);
      return;
    }
    setState(() => _statusMessage = "Generating audio...");
    try {
      final response = await http.post(
        Uri.parse("$_apiBaseUrl/api/signlanguagetranslator/generate-audio"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"text": _finalSentence}),
      ).timeout(const Duration(seconds: 15));

      final result = jsonDecode(response.body);
      if (result['success'] == true) {
        final String base64Audio = result['data']['audioData'];
        final int sampleRate = result['data']['sampleRate'];
        final Uint8List pcmBytes = base64Decode(base64Audio);
        final Uint8List wavBytes = addWavHeader(pcmBytes, sampleRate);

        final Directory tempDir = await getTemporaryDirectory();
        // اسم فريد لكل ملف صوت لتجنب التعارض
        final String fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.wav';
        final File tempFile = File('${tempDir.path}/$fileName');
        await tempFile.writeAsBytes(wavBytes);
        await _audioPlayer.play(DeviceFileSource(tempFile.path));
        _showSnackBar("Playing generated speech", Colors.green);
      } else {
        _showSnackBar(result['errorMessage'] ?? "Audio Generation failed", Colors.red);
      }
    } on TimeoutException {
      _showSnackBar("Audio request timed out.", Colors.red);
    } catch (e) {
      _showSnackBar("Audio Error: Request failed", Colors.red);
    } finally {
      if (mounted) {
        setState(() => _statusMessage = _isStreaming ? "Webcam active..." : (_isConnected ? "Connected" : "Disconnected"));
      }
    }
  }

  // ============================================================
  // Helpers
  // ============================================================
  void _clearLetters() {
    setState(() {
      _accumulatedLetters = "";
      _lastPrediction = "";
      _lastPredictionTime = 0;
      _currentLetter = "—";
      _finalSentence = "—";
    });
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Indicator
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  // مؤشر الاتصال
                  Icon(
                    Icons.circle,
                    size: 14,
                    color: _isReconnecting
                        ? Colors.orange
                        : (_isConnected ? Colors.green : Colors.red),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  // زر إعادة الاتصال اليدوي
                  if (!_isConnected && !_isReconnecting)
                    TextButton(
                      onPressed: () {
                        _reconnectAttempts = 0;
                        _connectToHub();
                      },
                      child: const Text("Reconnect", style: TextStyle(color: Colors.blue)),
                    ),
                  if (_isReconnecting)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Camera Preview
            Container(
              height: 300.h,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.hardEdge,
              child: _isStreaming &&
                      _cameraController != null &&
                      _cameraController!.value.isInitialized
                  ? Transform.scale(scaleX: -1, child: CameraPreview(_cameraController!))
                  : const Center(
                      child: Icon(Icons.videocam_off, color: Colors.white54, size: 50),
                    ),
            ),
            const SizedBox(height: 16),

            // Camera Controls
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_isStreaming || !_isConnected) ? null : _startCamera,
                    icon: const Icon(Icons.videocam),
                    label: const Text("Start"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isStreaming ? _stopCamera : null,
                    icon: const Icon(Icons.stop),
                    label: const Text("Stop"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Current Translation Box
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  const Text(
                    "CURRENT LETTER",
                    style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _currentLetter,
                    style: TextStyle(
                      fontSize: 48.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  Text("Accumulated: ${_accumulatedLetters.isEmpty ? '—' : _accumulatedLetters}"),
                  TextButton.icon(
                    onPressed: _clearLetters,
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text("Clear", style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Final Sentence Box
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  const Text(
                    "FINAL SENTENCE",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  Text(
                    _finalSentence,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _finalizeSentence,
                    icon: const Icon(Icons.spellcheck, color: Colors.pink),
                    label: const Text("Correct", style: TextStyle(color: Colors.pink)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.pink.shade50),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _generateSound,
                    icon: const Icon(Icons.volume_up, color: Colors.green),
                    label: const Text("Sound", style: TextStyle(color: Colors.green)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade50),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// WAV Header
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