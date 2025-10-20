import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../bloc/usage_bloc.dart';
import '../bloc/usage_state.dart';

/// Compact usage indicator widget for the app bar or chat screen
class UsageIndicator extends StatelessWidget {
  final bool showDetails;
  final VoidCallback? onTap;

  const UsageIndicator({super.key, this.showDetails = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UsageBloc, UsageState>(
      builder: (context, state) {
        if (state.quotaStatus == null) {
          return const SizedBox.shrink();
        }

        final quota = state.quotaStatus!;
        final color = _getColorForUsage(quota.usagePercentage);

        return InkWell(
          onTap: onTap ?? () => _showUsageDetails(context),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularPercentIndicator(
                  radius: 15.0,
                  lineWidth: 3.0,
                  percent: (quota.usagePercentage / 100).clamp(0.0, 1.0),
                  center: Text(
                    '${quota.usagePercentage.toInt()}%',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  progressColor: color,
                  backgroundColor: color.withOpacity(0.2),
                ),
                if (showDetails) ...[
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${quota.remainingMessages} messages',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${_formatTokens(quota.remainingTokens)} tokens left',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color.withOpacity(0.7),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: color.withOpacity(0.5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getColorForUsage(double percentage) {
    if (percentage >= 90) return Colors.red;
    if (percentage >= 75) return Colors.orange;
    if (percentage >= 50) return Colors.amber;
    return Colors.green;
  }

  String _formatTokens(int tokens) {
    if (tokens >= 1000000) {
      return '${(tokens / 1000000).toStringAsFixed(1)}M';
    }
    if (tokens >= 1000) {
      return '${(tokens / 1000).toStringAsFixed(1)}K';
    }
    return tokens.toString();
  }

  void _showUsageDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const UsageDetailsSheet(),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }
}

/// Detailed usage information bottom sheet
class UsageDetailsSheet extends StatelessWidget {
  const UsageDetailsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UsageBloc, UsageState>(
      builder: (context, state) {
        if (state.quotaStatus == null || state.usageStats == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final quota = state.quotaStatus!;
        final stats = state.usageStats!;
        final subscription = state.subscription;

        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Usage Details',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Subscription tier
              if (subscription != null) ...[
                _buildInfoCard(
                  context,
                  title: 'Subscription',
                  subtitle: subscription.currentTier.toUpperCase(),
                  icon: Icons.star,
                  color: _getTierColor(subscription.currentTier),
                ),
                const SizedBox(height: 12),
              ],

              // Daily usage
              _buildUsageCard(
                context,
                title: 'Daily Usage',
                used: stats.messagesThisDay,
                limit: quota.dailyMessageLimit,
                type: 'messages',
                icon: Icons.message,
              ),
              const SizedBox(height: 12),

              // Token usage
              _buildUsageCard(
                context,
                title: 'Token Usage',
                used: stats.tokensThisDay,
                limit: quota.dailyTokenLimit,
                type: 'tokens',
                icon: Icons.data_usage,
              ),
              const SizedBox(height: 12),

              // Reset time
              ...[
                _buildInfoCard(
                  context,
                  title: 'Next Reset',
                  subtitle: _formatResetTime(quota.nextResetDate),
                  icon: Icons.refresh,
                  color: Colors.blue,
                ),
                const SizedBox(height: 20),
              ],

              // Upgrade button for free/pro users
              if (subscription?.currentTier != 'premium') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showUpgradeDialog(context),
                    icon: const Icon(Icons.rocket_launch),
                    label: Text(
                      subscription?.currentTier == 'free'
                          ? 'Upgrade to Pro'
                          : 'Upgrade to Premium',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildUsageCard(
    BuildContext context, {
    required String title,
    required int used,
    required int limit,
    required String type,
    required IconData icon,
  }) {
    final percentage = limit > 0 ? (used / limit) : 0.0;
    final color = _getColorForPercentage(percentage);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text(
                '$used / ${_formatNumber(limit)}',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage.clamp(0.0, 1.0),
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(color),
          ),
          const SizedBox(height: 4),
          Text(
            '${(limit - used).clamp(0, limit)} $type remaining',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: color.withOpacity(0.8)),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'free':
        return Colors.grey;
      case 'pro':
        return Colors.blue;
      case 'premium':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getColorForPercentage(double percentage) {
    if (percentage >= 0.9) return Colors.red;
    if (percentage >= 0.75) return Colors.orange;
    if (percentage >= 0.5) return Colors.amber;
    return Colors.green;
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    }
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toString();
  }

  String _formatResetTime(DateTime resetTime) {
    final duration = resetTime.difference(DateTime.now());
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours.remainder(24)}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return 'Less than a minute';
    }
  }

  void _showUpgradeDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SubscriptionUpgradeScreen(),
      ),
    );
  }
}

/// Placeholder for subscription upgrade screen
class SubscriptionUpgradeScreen extends StatelessWidget {
  const SubscriptionUpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade Subscription')),
      body: const Center(child: Text('Subscription upgrade coming soon!')),
    );
  }
}
