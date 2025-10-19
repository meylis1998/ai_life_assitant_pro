import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDot(0),
        const SizedBox(width: 4),
        _buildDot(1),
        const SizedBox(width: 4),
        _buildDot(2),
      ],
    );
  }

  Widget _buildDot(int index) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        shape: BoxShape.circle,
      ),
    ).animate(
      onPlay: (controller) => controller.repeat(),
    ).scale(
      duration: const Duration(milliseconds: 600),
      delay: Duration(milliseconds: index * 200),
      begin: const Offset(1, 1),
      end: const Offset(1.3, 1.3),
      curve: Curves.easeInOut,
    ).then().scale(
      duration: const Duration(milliseconds: 600),
      begin: const Offset(1.3, 1.3),
      end: const Offset(1, 1),
      curve: Curves.easeInOut,
    );
  }
}