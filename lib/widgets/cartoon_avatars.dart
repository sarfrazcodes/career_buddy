import 'package:flutter/material.dart';

class CartoonAvatar extends StatelessWidget {
  final String type; // 'male' | 'female' | 'neutral'
  final double size;

  const CartoonAvatar({super.key, required this.type, this.size = 80});

  @override
  Widget build(BuildContext context) {
    // Map type to asset path – adjust file names as needed
    final assetPath = switch (type) {
      'male'   => 'assets/images/avatar_male.png',
      'female' => 'assets/images/avatar_female.png',
      _        => 'assets/images/avatar_male.png', // fallback for neutral etc.
    };

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (_, error, __) {
            // Fallback in case the image is missing
            return Container(
              color: Colors.grey.shade300,
              child: const Icon(Icons.person, size: 40, color: Colors.grey),
            );
          },
        ),
      ),
    );
  }
}