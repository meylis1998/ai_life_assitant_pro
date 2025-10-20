import 'package:flutter/material.dart';

import '../../../../core/constants/app_theme.dart';
import '../../domain/entities/chat_message.dart';

class AIProviderSelector extends StatelessWidget {
  final AIProvider currentProvider;
  final Function(AIProvider) onProviderChanged;

  const AIProviderSelector({
    super.key,
    required this.currentProvider,
    required this.onProviderChanged,
  });

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
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _ProviderChip(
                      provider: provider,
                      isSelected: isSelected,
                      onTap: () => onProviderChanged(provider),
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
}

class _ProviderChip extends StatelessWidget {
  final AIProvider provider;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProviderChip({
    required this.provider,
    required this.isSelected,
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
            color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
            border: Border.all(
              color: isSelected ? color : theme.dividerColor,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isSelected ? color : theme.disabledColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                provider.displayName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isSelected ? color : theme.textTheme.bodyMedium?.color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 4),
                Icon(Icons.check_circle, size: 16, color: color),
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
