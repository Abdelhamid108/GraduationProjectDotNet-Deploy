import 'package:flutter/material.dart';
import 'sign_card.dart'; // غيري الـ import ده حسب مكان الملف عندك

class WordSignCard extends StatelessWidget {
  final String wordLabel;
  final List<String?> imageUrls;

  const WordSignCard({
    super.key,
    required this.wordLabel,
    required this.imageUrls,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF5DBBFF),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Word label + sound icon
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                wordLabel,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  color: Color(0xFF30BBF9),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.volume_up_rounded,
                color: Color(0xFF30BBF9),
                size: 20,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Sign cards row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: imageUrls
                .map(
                  (url) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: SignCard(imageUrl: url),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}