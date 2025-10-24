import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/services/location_service.dart';
import '../../../../injection_container.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/text_styles.dart';

class LocationPermissionBanner extends StatefulWidget {
  final VoidCallback? onLocationGranted;

  const LocationPermissionBanner({
    super.key,
    this.onLocationGranted,
  });

  @override
  State<LocationPermissionBanner> createState() => _LocationPermissionBannerState();
}

class _LocationPermissionBannerState extends State<LocationPermissionBanner> {
  bool _isLoading = false;
  bool _isDismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorPalette.primary.withOpacity(0.1),
        border: Border.all(color: ColorPalette.primary.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on_outlined,
            color: ColorPalette.primary,
            size: 24.w,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Get Weather for Your Location',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ColorPalette.primary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Allow location access for accurate local weather',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          if (_isLoading)
            SizedBox(
              width: 20.w,
              height: 20.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(ColorPalette.primary),
              ),
            )
          else ...[
            TextButton(
              onPressed: () {
                setState(() {
                  _isDismissed = true;
                });
              },
              child: Text(
                'Later',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ),
            SizedBox(width: 4.w),
            ElevatedButton(
              onPressed: _requestLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPalette.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Allow',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _requestLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final locationService = sl<LocationService>();
      final position = await locationService.getCurrentPosition();

      if (position != null) {
        // Location granted and obtained
        setState(() {
          _isDismissed = true;
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location access granted! Weather will now use your current location.'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // Notify parent to refresh data
        widget.onLocationGranted?.call();
      } else {
        // Permission denied or location unavailable
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location access denied. You can enable it later in settings.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () async {
                  await locationService.openLocationSettings();
                },
              ),
            ),
          );
        }

        setState(() {
          _isDismissed = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}