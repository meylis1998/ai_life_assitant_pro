import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/chat'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Current Plan Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.workspace_premium,
                        color: Theme.of(context).colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Plan',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withAlpha(51),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'FREE',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _PlanFeature(
                    icon: Icons.message,
                    text: '50 messages per day',
                  ),
                  const _PlanFeature(
                    icon: Icons.data_usage,
                    text: '50,000 tokens per day',
                  ),
                  const _PlanFeature(
                    icon: Icons.api,
                    text: 'Gemini provider only',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Upgrade Section
          Text(
            'Upgrade to Pro',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 16),

          // Pro Plan Card
          _PlanCard(
            title: 'Pro Monthly',
            price: '\$19.99',
            period: '/month',
            features: const [
              'Unlimited messages',
              'Unlimited tokens',
              'All AI providers (Gemini, Claude, OpenAI)',
              'Priority support',
              'Advanced analytics',
            ],
            onTap: () {
              _showUpgradeDialog(context, 'Pro Monthly', '\$19.99/month');
            },
          ),

          const SizedBox(height: 16),

          // Pro Annual Card
          _PlanCard(
            title: 'Pro Annual',
            price: '\$199.99',
            period: '/year',
            badge: 'Save 17%',
            features: const [
              'All Pro Monthly features',
              'Priority customer support',
              'Early access to new features',
              'Custom AI model fine-tuning (coming soon)',
            ],
            highlighted: true,
            onTap: () {
              _showUpgradeDialog(context, 'Pro Annual', '\$199.99/year');
            },
          ),

          const SizedBox(height: 32),

          // Usage Stats (Placeholder)
          Text(
            'Today\'s Usage',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _UsageIndicator(
                    label: 'Messages',
                    used: 12,
                    total: 50,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  _UsageIndicator(
                    label: 'Tokens',
                    used: 24530,
                    total: 50000,
                    color: Colors.purple,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context, String plan, String price) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upgrade to $plan'),
        content: Text(
          'Payment integration coming soon!\n\nYou\'ll be charged $price and gain access to all premium features immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment integration coming soon!'),
                ),
              );
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final String? badge;
  final List<String> features;
  final bool highlighted;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    this.badge,
    required this.features,
    this.highlighted = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: highlighted ? 4 : 1,
      color: highlighted
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  period,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(feature),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onTap,
                child: const Text('Upgrade Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanFeature extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PlanFeature({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }
}

class _UsageIndicator extends StatelessWidget {
  final String label;
  final int used;
  final int total;
  final Color color;

  const _UsageIndicator({
    required this.label,
    required this.used,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (used / total * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              '$used / $total ($percentage%)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: used / total,
          backgroundColor: color.withAlpha(26),
          color: color,
          borderRadius: BorderRadius.circular(4),
          minHeight: 8,
        ),
      ],
    );
  }
}
