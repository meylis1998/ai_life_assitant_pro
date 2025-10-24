import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/calendar_event.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/color_palette.dart';

class CalendarTimeline extends StatelessWidget {
  final List<CalendarEvent> events;

  const CalendarTimeline({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.event_available, size: 48.w, color: Colors.grey[300]),
            SizedBox(height: 12.h),
            Text(
              'No events scheduled for today',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event, size: 24.w, color: ColorPalette.primary),
              SizedBox(width: 8.w),
              Text(
                'Today\'s Schedule (${events.length})',
                style: AppTextStyles.heading4.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...events.map((event) => _buildEventItem(event)),
        ],
      ),
    );
  }

  Widget _buildEventItem(CalendarEvent event) {
    final isOngoing = event.isOngoing;
    final isUpcoming = event.isUpcoming;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isOngoing
            ? ColorPalette.primary.withOpacity(0.1)
            : isUpcoming
                ? Colors.orange.withOpacity(0.1)
                : Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isOngoing
              ? ColorPalette.primary
              : isUpcoming
                  ? Colors.orange
                  : Colors.grey[200]!,
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4.w,
            height: 50.h,
            decoration: BoxDecoration(
              color: isOngoing
                  ? ColorPalette.primary
                  : isUpcoming
                      ? Colors.orange
                      : Colors.grey[400],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      event.isAllDay
                          ? 'All day'
                          : '${_formatTime(event.startTime)} - ${_formatTime(event.endTime)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isOngoing
                            ? ColorPalette.primary
                            : isUpcoming
                                ? Colors.orange
                                : Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isOngoing) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: ColorPalette.primary,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          'ONGOING',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  event.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (event.location != null) ...[
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14.w, color: Colors.grey[600]),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          event.location!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
