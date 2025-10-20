import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import '../widgets/social_auth_buttons.dart';
import '../widgets/email_auth_form.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is AuthAuthenticated) {
            // Router will handle navigation
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Welcome! Setting up your account...'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading || state is AuthOperationInProgress;

          return SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 32),

                        // App Icon/Logo
                        Icon(
                          Icons.psychology_rounded,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),

                        const SizedBox(height: 16),

                        // Title
                        Text(
                          'AI Life Assistant',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          'Your intelligent companion for daily tasks',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                              ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 48),

                        // Tab Bar
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            labelColor: Theme.of(context).colorScheme.onPrimary,
                            unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
                            dividerColor: Colors.transparent,
                            tabs: const [
                              Tab(text: 'Sign In'),
                              Tab(text: 'Sign Up'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Tab Content
                        SizedBox(
                          height: 420,
                          child: TabBarView(
                            controller: _tabController,
                            children: const [
                              // Sign In Tab
                              _AuthTabContent(isSignUp: false),

                              // Sign Up Tab
                              _AuthTabContent(isSignUp: true),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Terms and Privacy
                        Text(
                          'By continuing, you agree to our Terms of Service and Privacy Policy',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                // Loading Overlay
                if (isLoading)
                  Container(
                    color: Colors.black.withAlpha(26),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AuthTabContent extends StatelessWidget {
  final bool isSignUp;

  const _AuthTabContent({required this.isSignUp});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Social Auth Buttons
          const SocialAuthButtons(),

          const SizedBox(height: 24),

          // Divider with "OR"
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(26),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(26),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Email Auth Form
          EmailAuthForm(isSignUp: isSignUp),
        ],
      ),
    );
  }
}
