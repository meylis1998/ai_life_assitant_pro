import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../bloc/briefing_bloc.dart';
import '../widgets/greeting_header.dart';
import '../widgets/weather_card.dart';
import '../widgets/news_card.dart';
import '../widgets/calendar_timeline.dart';
import '../widgets/ai_insights_card.dart';
import '../widgets/briefing_loading_skeleton.dart';
import '../widgets/location_permission_banner.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/dependency_injection/injection_container.dart';

class BriefingPage extends StatelessWidget {
  const BriefingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<BriefingBloc>()
        ..add(const BriefingRequested()),
      child: const _BriefingPageContent(),
    );
  }
}

class _BriefingPageContent extends StatelessWidget {
  const _BriefingPageContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Daily Briefing',
          style: AppTextStyles.heading3.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              context.push('/briefing/settings');
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<BriefingBloc>().add(const BriefingRefreshed());
            },
          ),
        ],
      ),
      body: BlocBuilder<BriefingBloc, BriefingState>(
        builder: (context, state) {
          if (state is BriefingLoading) {
            return const BriefingLoadingSkeleton();
          }

          if (state is BriefingError) {
            return _buildErrorState(context, state);
          }

          if (state is BriefingLoaded) {
            return _buildBriefingContent(context, state);
          }

          return const Center(
            child: Text('Pull down to load your daily briefing'),
          );
        },
      ),
    );
  }

  Widget _buildBriefingContent(BuildContext context, BriefingLoaded state) {
    final briefing = state.briefing;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<BriefingBloc>().add(const BriefingRefreshed());
        await Future.delayed(const Duration(seconds: 2));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show cache indicator if data is from cache
            if (state.isFromCache)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.offline_bolt, color: Colors.orange),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Offline mode - Showing cached data',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Show errors if any (partial failure)
            if (briefing.hasErrors)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.red[700], size: 20.w),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        briefing.errorMessage,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.red[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Location Permission Banner
            // Show if weather is using London (fallback) or if no location is set
            if (_shouldShowLocationBanner(briefing, state.preferences))
              LocationPermissionBanner(
                onLocationGranted: () {
                  // Refresh the briefing when location is granted
                  context.read<BriefingBloc>().add(const BriefingRefreshed());
                },
              ),

            // Greeting
            if (briefing.insights != null)
              GreetingHeader(
                greeting: briefing.insights!.greeting,
                generatedAt: briefing.generatedAt,
              )
            else
              GreetingHeader(
                greeting: 'Good day!',
                generatedAt: briefing.generatedAt,
              ),

            SizedBox(height: 8.h),

            // Weather
            if (briefing.weather != null) ...[
              WeatherCard(weather: briefing.weather!),
              SizedBox(height: 16.h),
            ],

            // AI Insights
            if (briefing.insights != null) ...[
              AIInsightsCard(insights: briefing.insights!),
              SizedBox(height: 16.h),
            ],

            // Calendar
            CalendarTimeline(events: briefing.todayEvents),
            SizedBox(height: 16.h),

            // News Section Header
            if (briefing.topNews.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                child: Row(
                  children: [
                    Icon(Icons.newspaper, size: 24.w, color: ColorPalette.primary),
                    SizedBox(width: 8.w),
                    Text(
                      'Top News (${briefing.newsCount})',
                      style: AppTextStyles.heading4.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),

              // News Articles
              ...briefing.topNews.map((article) => NewsCard(article: article)),

              SizedBox(height: 32.h),
            ],

            // Empty state if no content
            if (!briefing.hasContent)
              Padding(
                padding: EdgeInsets.all(32.w),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.cloud_off, size: 64.w, color: Colors.grey),
                      SizedBox(height: 16.h),
                      Text(
                        'No briefing data available',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      ElevatedButton.icon(
                        onPressed: () {
                          context.read<BriefingBloc>().add(
                                const BriefingRequested(forceRefresh: true),
                              );
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, BriefingError state) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<BriefingBloc>().add(const BriefingRequested(forceRefresh: true));
        await Future.delayed(const Duration(seconds: 2));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height - 100.h,
          padding: EdgeInsets.all(32.w),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64.w, color: Colors.red),
                SizedBox(height: 16.h),
                Text(
                  'Failed to load briefing',
                  style: AppTextStyles.heading4.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  state.message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<BriefingBloc>().add(
                          const BriefingRequested(forceRefresh: true),
                        );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 12.h,
                    ),
                  ),
                ),
                if (state.cachedBriefing != null) ...[
                  SizedBox(height: 16.h),
                  TextButton.icon(
                    onPressed: () {
                      context.read<BriefingBloc>().add(
                            const CachedBriefingRequested(),
                          );
                    },
                    icon: const Icon(Icons.offline_bolt),
                    label: const Text('View Cached Briefing'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Check if location permission banner should be shown
  bool _shouldShowLocationBanner(briefing, preferences) {
    // Show banner if:
    // 1. Weather location is London (fallback)
    // 2. Weather location is Mountain View (another common fallback)
    // 3. No saved coordinates in preferences
    // 4. Weather shows fallback location but user hasn't explicitly set it

    final location = briefing.weather?.location?.toLowerCase() ?? '';

    // Check for common fallback locations
    final isFallbackLocation = location.contains('london') ||
                              location.contains('mountain view');

    if (isFallbackLocation) {
      // Check if user explicitly set this as their preferred city
      final preferredCity = preferences.preferredCity?.toLowerCase() ?? '';
      final userSetThisCity = location.contains(preferredCity) && preferredCity.isNotEmpty;

      if (userSetThisCity) {
        return false; // User intentionally chose this city
      }

      // If no coordinates saved and weather is fallback location, show banner
      if (preferences.latitude == null || preferences.longitude == null) {
        return true;
      }
    }

    return false;
  }
}
