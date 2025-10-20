import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/chat'),
        ),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.currentUser;

          if (user == null) {
            return const Center(
              child: Text('Not authenticated'),
            );
          }

          return ListView(
            children: [
              // Profile Section
              _Section(
                title: 'Profile',
                children: [
                  _ListItem(
                    icon: Icons.person_outline,
                    title: 'Display Name',
                    subtitle: user.displayName ?? 'Not set',
                    onTap: () {
                      // TODO: Implement edit name
                    },
                  ),
                  _ListItem(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    subtitle: user.email ?? 'No email',
                    trailing: user.emailVerified
                        ? const Icon(Icons.verified, color: Colors.green, size: 20)
                        : const Text(
                            'Not verified',
                            style: TextStyle(color: Colors.orange),
                          ),
                  ),
                  if (user.phoneNumber != null)
                    _ListItem(
                      icon: Icons.phone_outlined,
                      title: 'Phone',
                      subtitle: user.phoneNumber!,
                    ),
                ],
              ),

              // Linked Accounts
              _Section(
                title: 'Linked Accounts',
                children: [
                  _ListItem(
                    icon: Icons.g_mobiledata,
                    title: 'Google',
                    trailing: user.providers.contains('google.com')
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : TextButton(
                            onPressed: () {
                              context.read<AuthBloc>().add(const AuthLinkGoogleRequested());
                            },
                            child: const Text('Link'),
                          ),
                  ),
                  _ListItem(
                    icon: Icons.apple,
                    title: 'Apple',
                    trailing: user.providers.contains('apple.com')
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : TextButton(
                            onPressed: () {
                              context.read<AuthBloc>().add(const AuthLinkAppleRequested());
                            },
                            child: const Text('Link'),
                          ),
                  ),
                  _ListItem(
                    icon: Icons.email_outlined,
                    title: 'Email/Password',
                    trailing: user.providers.contains('password')
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.cancel, color: Colors.grey),
                  ),
                ],
              ),

              // Security
              _Section(
                title: 'Security',
                children: [
                  _ListItem(
                    icon: Icons.fingerprint,
                    title: 'Biometric Authentication',
                    trailing: Switch(
                      value: user.biometricEnabled,
                      onChanged: (value) {
                        context.read<AuthBloc>().add(
                              AuthBiometricToggleRequested(value),
                            );
                      },
                    ),
                  ),
                  if (user.providers.contains('password'))
                    _ListItem(
                      icon: Icons.lock_outline,
                      title: 'Change Password',
                      onTap: () {
                        // TODO: Implement change password
                      },
                    ),
                ],
              ),

              // Subscription
              _Section(
                title: 'Subscription',
                children: [
                  _ListItem(
                    icon: Icons.workspace_premium,
                    title: 'Manage Subscription',
                    subtitle: 'View and manage your plan',
                    onTap: () => context.go('/subscription'),
                  ),
                ],
              ),

              // Account Actions
              _Section(
                title: 'Account',
                children: [
                  _ListItem(
                    icon: Icons.logout,
                    title: 'Sign Out',
                    titleColor: Theme.of(context).colorScheme.error,
                    onTap: () {
                      _showSignOutDialog(context);
                    },
                  ),
                  _ListItem(
                    icon: Icons.delete_forever,
                    title: 'Delete Account',
                    titleColor: Colors.red,
                    subtitle: 'Permanently delete your account and data',
                    onTap: () {
                      _showDeleteAccountDialog(context);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Account Info
              Center(
                child: Text(
                  'Account created: ${_formatDate(user.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
                      ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              dialogContext.pop();
              context.read<AuthBloc>().add(const AuthSignOutRequested());
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              dialogContext.pop();
              context.read<AuthBloc>().add(const AuthDeleteAccountRequested());
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _ListItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  const _ListItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(
        title,
        style: TextStyle(color: titleColor),
      ),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
