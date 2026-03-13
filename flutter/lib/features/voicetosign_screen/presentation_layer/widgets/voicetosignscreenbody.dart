import 'package:flutter/material.dart';
import 'package:graduationproject/core/widgets/word_signcard.dart';

class VoiceToSignScreenBody extends StatefulWidget {
  const VoiceToSignScreenBody({super.key});

  @override
  State<VoiceToSignScreenBody> createState() => _VoiceToSignScreenBodyState();
}

class _VoiceToSignScreenBodyState extends State<VoiceToSignScreenBody>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  final List<String> bismiImages = [
    'https://placehold.co/80x80/98DCFA/FFFFFF?text=ب',
    'https://placehold.co/80x80/98DCFA/FFFFFF?text=س',
    'https://placehold.co/80x80/98DCFA/FFFFFF?text=م',
  ];

  final List<String> allahImages = [
    'https://placehold.co/80x80/98DCFA/FFFFFF?text=ا',
    'https://placehold.co/80x80/98DCFA/FFFFFF?text=ل',
    'https://placehold.co/80x80/98DCFA/FFFFFF?text=ل',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Column(
          children: [
            // Back arrow + Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFF2BBBFA),
                      size: 22,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'تحويل الصوت الى لغة الاشارة',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF2BBBFA),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 22),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Waveform + Mic Button
            SizedBox(
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Waveform
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      20,
                      (i) => AnimatedContainer(
                        duration: Duration(milliseconds: 300 + (i * 50)),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 4,
                        height: _isRecording
                            ? (10 + (i % 5) * 12).toDouble()
                            : 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5DBBFF).withOpacity(0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // Mic Button
                  GestureDetector(
                    onTap: () =>
                        setState(() => _isRecording = !_isRecording),
                    child: ScaleTransition(
                      scale: _isRecording
                          ? _scaleAnim
                          : const AlwaysStoppedAnimation(1.0),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF30BBF9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  const Color(0xFF30BBF9).withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isRecording
                              ? Icons.stop_rounded
                              : Icons.mic_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Buttons Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  // Voice Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _isRecording = !_isRecording),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF30BBF9),
                          borderRadius: BorderRadius.circular(35),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isRecording ? Icons.stop : Icons.mic,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isRecording ? 'إيقاف' : 'تسجيل صوتي',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Convert Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // TODO: اضيفي هنا logic التحويل
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF44BCF0), Color(0xFF276C8A)],
                          ),
                          borderRadius: BorderRadius.circular(35),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.copy, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'تحويل النص',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Results - scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    WordSignCard(
                      wordLabel: 'كلمة : بسم',
                      imageUrls: bismiImages,
                    ),
                    const SizedBox(height: 12),
                    WordSignCard(
                      wordLabel: 'كلمة : الله',
                      imageUrls: allahImages,
                    ),
                    const SizedBox(height: 16),

                    // Back Button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 260,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF30BBF9),
                          borderRadius: BorderRadius.circular(35),
                        ),
                        child: const Center(
                          child: Text(
                            'الرجوع',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}