import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_in_button/sign_in_button.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          } else if (state is AuthOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary.withOpacity(0.1),
                theme.colorScheme.secondary.withOpacity(0.05),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo/Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.psychology,
                        size: 60,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ).animate().fadeIn(duration: 600.ms).scale(delay: 200.ms),

                    const SizedBox(height: 40),

                    // App Title
                    Text(
                          'AI Life Assistant',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 600.ms)
                        .slideY(begin: 0.3, end: 0),

                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                          'Your intelligent companion for life',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 600.ms, duration: 600.ms)
                        .slideY(begin: 0.3, end: 0),

                    const SizedBox(height: 60),

                    // Welcome Text
                    Text(
                      'Welcome',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ).animate().fadeIn(delay: 800.ms, duration: 600.ms),

                    const SizedBox(height: 8),

                    Text(
                      'Sign in to get started',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ).animate().fadeIn(delay: 900.ms, duration: 600.ms),

                    const SizedBox(height: 40),

                    // Sign-in Buttons
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Column(
                        children: [
                          // Google Sign-In
                          BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  final isLoading =
                                      state is AuthOperationInProgress &&
                                      state.operation.contains('Google');

                                  return SignInButton(
                                    Buttons.google,
                                    text: 'Continue with Google',
                                    onPressed: isLoading
                                        ? () {} // Disabled during loading
                                        : () {
                                            context.read<AuthBloc>().add(
                                              const AuthSignInWithGoogleRequested(),
                                            );
                                          },
                                  );
                                },
                              )
                              .animate()
                              .fadeIn(delay: 1000.ms, duration: 600.ms)
                              .slideX(begin: -0.2, end: 0),

                          const SizedBox(height: 16),

                          // Apple Sign-In
                          BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  final isLoading =
                                      state is AuthOperationInProgress &&
                                      state.operation.contains('Apple');

                                  return SignInButton(
                                    Buttons.apple,
                                    text: 'Continue with Apple',
                                    onPressed: isLoading
                                        ? () {} // Disabled during loading
                                        : () {
                                            context.read<AuthBloc>().add(
                                              const AuthSignInWithAppleRequested(),
                                            );
                                          },
                                  );
                                },
                              )
                              .animate()
                              .fadeIn(delay: 1100.ms, duration: 600.ms)
                              .slideX(begin: -0.2, end: 0),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Privacy Policy and Terms
                    Text.rich(
                      TextSpan(
                        text: 'By signing in, you agree to our ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        children: [
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 1200.ms, duration: 600.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
