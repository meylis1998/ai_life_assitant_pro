import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_theme.dart';
import '../../domain/entities/chat_message.dart';

class AIProviderSelector extends StatelessWidget {
  final AIProvider currentProvider;
  final String userTier;
  final Function(AIProvider) onProviderChanged;

  const AIProviderSelector({
    super.key,
    required this.currentProvider,
    required this.userTier,
    required this.onProviderChanged,
  });

  bool _isProviderLocked(AIProvider provider) {
    // Free tier can only use Gemini
    if (userTier.toLowerCase() == 'free') {
      return provider != AIProvider.gemini;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'AI Provider:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: AIProvider.values.map((provider) {
                  final isSelected = provider == currentProvider;
                  final isLocked = _isProviderLocked(provider);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _ProviderChip(
                      provider: provider,
                      isSelected: isSelected,
                      isLocked: isLocked,
                      onTap: () {
                        if (isLocked) {
                          _showUpgradeDialog(context, provider);
                        } else {
                          onProviderChanged(provider);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context, AIProvider provider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.workspace_premium, color: Colors.purple),
            const SizedBox(width: 8),
            Text('Upgrade to Pro'),
          ],
        ),
        content: Text(
          'Unlock ${provider.displayName} and other premium AI providers by upgrading to Pro.\n\n'
          '✓ Unlimited messages\n'
          '✓ All AI providers\n'
          '✓ Priority support',
        ),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(),
            child: const Text('Maybe Later'),
          ),
          FilledButton(
            onPressed: () {
              dialogContext.pop();
              context.go('/subscription');
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }
}

class _ProviderChip extends StatelessWidget {
  final AIProvider provider;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback onTap;

  const _ProviderChip({
    required this.provider,
    required this.isSelected,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getProviderColor(provider);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isLocked
                ? theme.disabledColor.withOpacity(0.1)
                : isSelected
                    ? color.withOpacity(0.2)
                    : Colors.transparent,
            border: Border.all(
              color: isLocked
                  ? theme.disabledColor
                  : isSelected
                      ? color
                      : theme.dividerColor,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLocked) ...[
                Icon(
                  Icons.lock,
                  size: 14,
                  color: theme.disabledColor,
                ),
                const SizedBox(width: 6),
              ] else ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isSelected ? color : theme.disabledColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                provider.displayName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isLocked
                      ? theme.disabledColor
                      : isSelected
                          ? color
                          : theme.textTheme.bodyMedium?.color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              if (isSelected && !isLocked) ...[
                const SizedBox(width: 4),
                Icon(Icons.check_circle, size: 16, color: color),
              ],
              if (isLocked) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.withAlpha(51),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                      color: Colors.purple,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getProviderColor(AIProvider provider) {
    switch (provider) {
      case AIProvider.gemini:
        return AppTheme.geminiColor;
      case AIProvider.claude:
        return AppTheme.claudeColor;
      case AIProvider.openai:
        return AppTheme.openAIColor;
    }
  }
}
