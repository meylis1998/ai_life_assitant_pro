import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

class EmailAuthForm extends StatefulWidget {
  final bool isSignUp;

  const EmailAuthForm({
    super.key,
    required this.isSignUp,
  });

  @override
  State<EmailAuthForm> createState() => _EmailAuthFormState();
}

class _EmailAuthFormState extends State<EmailAuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (widget.isSignUp && value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (widget.isSignUp) {
      if (value == null || value.isEmpty) {
        return 'Please confirm your password';
      }
      if (value != _passwordController.text) {
        return 'Passwords do not match';
      }
    }
    return null;
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (widget.isSignUp) {
        context.read<AuthBloc>().add(
              AuthSignUpRequested(
                email: _emailController.text.trim(),
                password: _passwordController.text,
                displayName: _displayNameController.text.trim().isEmpty
                    ? ''
                    : _displayNameController.text.trim(),
              ),
            );
      } else {
        context.read<AuthBloc>().add(
              AuthSignInWithEmailRequested(
                email: _emailController.text.trim(),
                password: _passwordController.text,
              ),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Display Name (Sign Up only)
          if (widget.isSignUp) ...[
            TextFormField(
              controller: _displayNameController,
              decoration: InputDecoration(
                labelText: 'Display Name (Optional)',
                hintText: 'How should we call you?',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
          ],

          // Email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: _validateEmail,
            textInputAction: TextInputAction.next,
          ),

          const SizedBox(height: 16),

          // Password
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: widget.isSignUp
                  ? 'Min. 8 characters'
                  : 'Enter your password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: _validatePassword,
            textInputAction:
                widget.isSignUp ? TextInputAction.next : TextInputAction.done,
            onFieldSubmitted: widget.isSignUp ? null : (_) => _submit(),
          ),

          // Confirm Password (Sign Up only)
          if (widget.isSignUp) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                hintText: 'Re-enter your password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: _validateConfirmPassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
            ),
          ],

          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                widget.isSignUp ? 'Sign Up' : 'Sign In',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Password strength indicator (Sign Up only)
          if (widget.isSignUp) ...[
            const SizedBox(height: 16),
            _PasswordStrengthIndicator(
              password: _passwordController.text,
            ),
          ],
        ],
      ),
    );
  }
}

class _PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const _PasswordStrengthIndicator({required this.password});

  _PasswordStrength _getStrength() {
    if (password.isEmpty) return _PasswordStrength.none;
    if (password.length < 8) return _PasswordStrength.weak;

    int strength = 0;
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;

    if (strength <= 2) return _PasswordStrength.medium;
    return _PasswordStrength.strong;
  }

  @override
  Widget build(BuildContext context) {
    final strength = _getStrength();

    if (strength == _PasswordStrength.none) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: strength.value,
                backgroundColor: Colors.grey.shade200,
                color: strength.color,
                borderRadius: BorderRadius.circular(4),
                minHeight: 4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Password strength: ${strength.label}',
          style: TextStyle(
            fontSize: 12,
            color: strength.color,
          ),
        ),
      ],
    );
  }
}

enum _PasswordStrength {
  none(0, '', Colors.grey),
  weak(0.33, 'Weak', Colors.red),
  medium(0.66, 'Medium', Colors.orange),
  strong(1.0, 'Strong', Colors.green);

  final double value;
  final String label;
  final Color color;

  const _PasswordStrength(this.value, this.label, this.color);
}
