import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';

import '../bloc/usage_bloc.dart';
import '../bloc/usage_state.dart';
import '../bloc/usage_event.dart';

/// Card widget showing usage statistics and trends
class UsageStatisticsCard extends StatelessWidget {
  const UsageStatisticsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UsageBloc, UsageState>(
      builder: (context, state) {
        if (state.usageStats == null) {
          return const Card(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        final stats = state.usageStats!;
        final quota = state.quotaStatus;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Usage Statistics',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      onPressed: () {
                        context.read<UsageBloc>().add(
                          RefreshUsageStats(
                            userId: stats.userId,
                            forceRefresh: true,
                          ),
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Today's usage summary
                Row(
                  children: [
                    Expanded(
                      child: _buildStatTile(
                        context,
                        title: 'Messages Today',
                        value: stats.messagesThisDay.toString(),
                        icon: Icons.message,
                        color: Colors.blue,
                        subtitle: quota != null
                            ? '${quota.remainingMessages} left'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatTile(
                        context,
                        title: 'Tokens Today',
                        value: _formatTokens(stats.tokensThisDay),
                        icon: Icons.data_usage,
                        color: Colors.green,
                        subtitle: quota != null
                            ? '${_formatTokens(quota.remainingTokens)} left'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Monthly stats
                Row(
                  children: [
                    Expanded(
                      child: _buildStatTile(
                        context,
                        title: 'This Month',
                        value: stats.messagesThisMonth.toString(),
                        icon: Icons.calendar_month,
                        color: Colors.purple,
                        subtitle: 'messages',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatTile(
                        context,
                        title: 'Est. Cost',
                        value:
                            '\$${((stats.tokensThisMonth / 1000) * 0.001).toStringAsFixed(2)}',
                        icon: Icons.attach_money,
                        color: Colors.orange,
                        subtitle: 'this month',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Usage chart
                SizedBox(height: 200, child: _buildUsageChart(context, stats)),
                const SizedBox(height: 16),

                // View detailed analytics button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.read<UsageBloc>().add(
                        GetUsageAnalytics(userId: stats.userId),
                      );
                      _showAnalyticsDialog(context);
                    },
                    icon: const Icon(Icons.analytics),
                    label: const Text('View Detailed Analytics'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatTile(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: color.withOpacity(0.7)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUsageChart(BuildContext context, dynamic stats) {
    // Mock data for demonstration - would be real historical data
    final spots = List.generate(7, (index) {
      return FlSpot(
        index.toDouble(),
        (20 - (index * 2) + (index % 2 * 5)).toDouble(),
      );
    });

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 10,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).dividerColor.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                if (value.toInt() >= 0 && value.toInt() < days.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      days[value.toInt()],
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 10,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.3),
              width: 1,
            ),
            left: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: 30,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.7),
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: Theme.of(context).colorScheme.primary,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  Theme.of(context).colorScheme.primary.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
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

  void _showAnalyticsDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const AnalyticsDialog());
  }
}

/// Analytics dialog showing detailed usage information
class AnalyticsDialog extends StatelessWidget {
  const AnalyticsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: BlocBuilder<UsageBloc, UsageState>(
          builder: (context, state) {
            if (state is UsageAnalyticsLoaded) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Usage Analytics',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Analytics content
                  _buildAnalyticsRow(
                    'Total Messages',
                    state.totalMessages.toString(),
                    Icons.message,
                    Colors.blue,
                  ),
                  const Divider(height: 24),
                  _buildAnalyticsRow(
                    'Total Tokens',
                    _formatNumber(state.totalTokens),
                    Icons.data_usage,
                    Colors.green,
                  ),
                  const Divider(height: 24),
                  _buildAnalyticsRow(
                    'Total Cost',
                    '\$${state.totalCost.toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.orange,
                  ),
                  const SizedBox(height: 20),

                  // Provider breakdown
                  if (state.providerUsage.isNotEmpty) ...[
                    Text(
                      'Provider Usage',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ...state.providerUsage.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key),
                            Text(
                              '${entry.value} messages',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              );
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildAnalyticsRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(child: Text(label)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    }
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
