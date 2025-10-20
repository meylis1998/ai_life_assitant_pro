import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

class SocialAuthButtons extends StatelessWidget {
  const SocialAuthButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Google Sign In Button
        _SocialButton(
          onPressed: () {
            context.read<AuthBloc>().add(const AuthSignInWithGoogleRequested());
          },
          icon: Icons.g_mobiledata,
          label: 'Continue with Google',
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          borderColor: Colors.grey.shade300,
        ),

        const SizedBox(height: 12),

        // Apple Sign In Button (only on iOS/macOS)
        if (Platform.isIOS || Platform.isMacOS)
          _SocialButton(
            onPressed: () {
              context.read<AuthBloc>().add(const AuthSignInWithAppleRequested());
            },
            icon: Icons.apple,
            label: 'Continue with Apple',
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;

  const _SocialButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          side: BorderSide(
            color: borderColor ?? backgroundColor,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
