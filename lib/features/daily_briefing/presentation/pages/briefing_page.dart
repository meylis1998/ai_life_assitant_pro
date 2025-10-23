import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/briefing_bloc.dart';
import '../bloc/briefing_event.dart';
import '../bloc/briefing_state.dart';
import '../widgets/weather_card.dart';
import '../widgets/news_list_widget.dart';
import '../widgets/calendar_timeline_widget.dart';
import '../widgets/ai_insights_card.dart';

class BriefingPage extends StatefulWidget {
  const BriefingPage({super.key});

  @override
  State<BriefingPage> createState() => _BriefingPageState();
}

class _BriefingPageState extends State<BriefingPage> {
  @override
  void initState() {
    super.initState();
    _loadBriefing();
  }

  void _loadBriefing() {
    final authState = context.read<AuthBloc>().state;
    String? userName;

    if (authState is AuthAuthenticated) {
      userName = authState.user.displayName;
    }

    context.read<BriefingBloc>().add(
          BriefingRequested(
            userName: userName,
            cityName: 'New York', // TODO: Get from user preferences
          ),
        );
  }

  void _refreshBriefing() {
    final authState = context.read<AuthBloc>().state;
    String? userName;

    if (authState is AuthAuthenticated) {
      userName = authState.user.displayName;
    }

    context.read<BriefingBloc>().add(
          BriefingRefreshRequested(
            userName: userName,
            cityName: 'New York',
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<BriefingBloc, BriefingState>(
        builder: (context, state) {
          if (state is BriefingLoading && state is! BriefingLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BriefingError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _refreshBriefing,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          if (state is BriefingLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                _refreshBriefing();
                await Future.delayed(const Duration(seconds: 1));
              },
              child: CustomScrollView(
                slivers: [
                  // App Bar with greeting
                  SliverAppBar(
                    expandedHeight: 120,
                    floating: false,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            DateFormat('EEEE, MMM d').format(DateTime.now()),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                    ),
                    actions: [
                      if (state.isCached)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Chip(
                            label: Text('Cached', style: TextStyle(fontSize: 10)),
                            backgroundColor: Colors.orange,
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _refreshBriefing,
                      ),
                    ],
                  ),

                  // Content
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // AI Insights
                        AIInsightsCard(insights: state.briefing.insights),
                        const SizedBox(height: 16),

                        // Weather
                        WeatherCard(weather: state.briefing.weather),
                        const SizedBox(height: 16),

                        // Calendar Events
                        if (state.briefing.todayEvents.isNotEmpty) ...[
                          CalendarTimelineWidget(
                            events: state.briefing.todayEvents,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // News
                        NewsListWidget(articles: state.briefing.topNews),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          }

          return const Center(child: Text('Pull down to load your briefing'));
        },
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}
