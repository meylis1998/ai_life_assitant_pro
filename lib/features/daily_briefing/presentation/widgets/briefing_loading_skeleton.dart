import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

class BriefingLoadingSkeleton extends StatelessWidget {
  const BriefingLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting skeleton
          _buildShimmerBox(
            width: 200.w,
            height: 32.h,
            margin: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 8.h),
          ),
          _buildShimmerBox(
            width: 120.w,
            height: 16.h,
            margin: EdgeInsets.symmetric(horizontal: 20.w),
          ),

          SizedBox(height: 24.h),

          // Weather card skeleton
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            height: 280.h,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // AI Insights skeleton
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            height: 200.h,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // Calendar skeleton
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            height: 150.h,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // News skeletons
          ...List.generate(
            2,
            (index) => Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              height: 240.h,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      margin: margin,
      width: width,
      height: height,
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      ),
    );
  }
}
