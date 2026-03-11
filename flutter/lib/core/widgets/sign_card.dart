import 'package:flutter/material.dart';

class SignCard extends StatelessWidget {
  final String? imageUrl;

  const SignCard({super.key, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 85,
      height: 85,
      decoration: BoxDecoration(
        color: const Color(0xFF98DCFA),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: imageUrl != null
            ? Image.network(
                imageUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.front_hand,
                  size: 40,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.front_hand,
                size: 40,
                color: Colors.white,
              ),
      ),
    );
  }
}