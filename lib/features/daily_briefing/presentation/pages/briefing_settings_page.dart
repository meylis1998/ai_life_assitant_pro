import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/repositories/briefing_repository.dart';
import '../../domain/usecases/schedule_briefing_usecase.dart';
import '../bloc/briefing_bloc.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/dependency_injection/injection_container.dart';
import '../../../../core/services/briefing_preferences_service.dart';

class BriefingSettingsPage extends StatefulWidget {
  const BriefingSettingsPage({super.key});

  @override
  State<BriefingSettingsPage> createState() => _BriefingSettingsPageState();
}

class _BriefingSettingsPageState extends State<BriefingSettingsPage> {
  final _cityController = TextEditingController();
  final _userNameController = TextEditingController();

  String? _selectedCountry = 'us';
  final List<String> _selectedCategories = [];
  final List<String> _interests = [];
  bool _useCurrentLocation = false;
  double? _latitude;
  double? _longitude;

  // Schedule settings
  bool _scheduleEnabled = false;
  TimeOfDay _scheduleTime = const TimeOfDay(hour: 7, minute: 0);
  bool _notificationsEnabled = true;

  final List<String> _availableCountries = [
    'us',
    'gb',
    'ca',
    'au',
    'de',
    'fr',
    'jp',
    'cn',
  ];

  final Map<String, String> _countryNames = {
    'us': 'United States',
    'gb': 'United Kingdom',
    'ca': 'Canada',
    'au': 'Australia',
    'de': 'Germany',
    'fr': 'France',
    'jp': 'Japan',
    'cn': 'China',
  };

  final List<String> _availableCategories = [
    'general',
    'business',
    'technology',
    'sports',
    'entertainment',
    'health',
    'science',
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final bloc = context.read<BriefingBloc>();
    bloc.add(const PreferencesRequested());

    // Load schedule preferences
    try {
      final prefsService = sl<BriefingPreferencesService>();
      setState(() {
        _scheduleEnabled = prefsService.scheduleEnabled;
        _scheduleTime = TimeOfDay(
          hour: prefsService.scheduleHour,
          minute: prefsService.scheduleMinute,
        );
        _notificationsEnabled = prefsService.notificationsEnabled;
      });
    } catch (e) {
      // Handle error silently - use defaults
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    _userNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Briefing Settings',
          style: AppTextStyles.heading3.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: BlocListener<BriefingBloc, BriefingState>(
        listener: (context, state) {
          if (state is PreferencesLoaded) {
            _cityController.text = state.preferences.preferredCity ?? '';
            _userNameController.text = state.preferences.userName ?? '';
            _selectedCountry = state.preferences.country ?? 'us';
            _latitude = state.preferences.latitude;
            _longitude = state.preferences.longitude;

            if (state.preferences.newsCategories != null) {
              _selectedCategories.clear();
              _selectedCategories.addAll(state.preferences.newsCategories!);
            }

            if (state.preferences.interests != null) {
              _interests.clear();
              _interests.addAll(state.preferences.interests!);
            }

            setState(() {
              _useCurrentLocation = _latitude != null && _longitude != null;
            });
          }
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                title: 'Personal',
                icon: Icons.person_outline,
                children: [
                  _buildTextField(
                    controller: _userNameController,
                    label: 'Your Name',
                    hint: 'Enter your name (optional)',
                    icon: Icons.person,
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              _buildSection(
                title: 'Location & Weather',
                icon: Icons.location_on_outlined,
                children: [
                  _buildSwitchTile(
                    title: 'Use Current Location',
                    subtitle: 'Get weather for your current location',
                    value: _useCurrentLocation,
                    onChanged: (value) async {
                      if (value) {
                        await _requestLocationPermission();
                      } else {
                        setState(() {
                          _useCurrentLocation = false;
                          _latitude = null;
                          _longitude = null;
                        });
                      }
                    },
                  ),

                  if (!_useCurrentLocation) ...[
                    SizedBox(height: 16.h),
                    _buildTextField(
                      controller: _cityController,
                      label: 'City Name',
                      hint: 'Enter city name (e.g., Ashgabat, Mary, Turkmenbashi)',
                      icon: Icons.location_city,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Popular Turkmenistan cities: Ashgabat, Mary, Turkmenbashi, Turkmenabat, Balkanabat',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),

              SizedBox(height: 24.h),

              _buildSection(
                title: 'News Preferences',
                icon: Icons.newspaper,
                children: [
                  _buildDropdown(
                    label: 'Country',
                    value: _selectedCountry,
                    items: _availableCountries,
                    itemBuilder: (country) => _countryNames[country] ?? country,
                    onChanged: (value) {
                      setState(() {
                        _selectedCountry = value;
                      });
                    },
                  ),

                  SizedBox(height: 16.h),

                  Text(
                    'News Categories',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: _availableCategories.map((category) {
                      final isSelected = _selectedCategories.contains(category);
                      return FilterChip(
                        label: Text(
                          category[0].toUpperCase() + category.substring(1),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategories.add(category);
                            } else {
                              _selectedCategories.remove(category);
                            }
                          });
                        },
                        backgroundColor: Colors.white,
                        selectedColor: ColorPalette.primary.withOpacity(0.2),
                        checkmarkColor: ColorPalette.primary,
                      );
                    }).toList(),
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              _buildSection(
                title: 'Schedule & Notifications',
                icon: Icons.schedule,
                children: [
                  _buildSwitchTile(
                    title: 'Enable Daily Briefing',
                    subtitle: 'Get your briefing at a scheduled time',
                    value: _scheduleEnabled,
                    onChanged: (value) {
                      setState(() {
                        _scheduleEnabled = value;
                      });
                    },
                  ),

                  if (_scheduleEnabled) ...[
                    SizedBox(height: 16.h),
                    _buildTimePicker(),
                    SizedBox(height: 16.h),
                    _buildSwitchTile(
                      title: 'Push Notifications',
                      subtitle: 'Receive notifications when briefing is ready',
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                      },
                    ),
                  ],
                ],
              ),

              SizedBox(height: 32.h),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _savePreferences,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Save Preferences',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
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
              Icon(icon, size: 24.w, color: ColorPalette.primary),
              SizedBox(width: 8.w),
              Text(
                title,
                style: AppTextStyles.heading4.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: ColorPalette.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(
          color: Colors.grey[600],
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: ColorPalette.primary,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required String Function(String) itemBuilder,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(itemBuilder(item)),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: ColorPalette.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Schedule Time',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        InkWell(
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: _scheduleTime,
            );
            if (time != null) {
              setState(() {
                _scheduleTime = time;
              });
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, color: ColorPalette.primary),
                SizedBox(width: 12.w),
                Text(
                  _scheduleTime.format(context),
                  style: AppTextStyles.bodyMedium,
                ),
                const Spacer(),
                Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showError(
        'Location permissions are permanently denied. Please enable in settings.',
      );
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _useCurrentLocation = true;
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      _showError('Failed to get location: $e');
    }
  }

  void _savePreferences() async {
    // Save briefing preferences
    final preferences = BriefingPreferences(
      preferredCity: _cityController.text.isNotEmpty ? _cityController.text : null,
      latitude: _latitude,
      longitude: _longitude,
      country: _selectedCountry,
      newsCategories: _selectedCategories.isNotEmpty ? _selectedCategories : null,
      userName: _userNameController.text.isNotEmpty ? _userNameController.text : null,
      interests: _interests.isNotEmpty ? _interests : null,
    );

    context.read<BriefingBloc>().add(PreferencesSaved(preferences));

    // Save schedule preferences
    try {
      final prefsService = sl<BriefingPreferencesService>();
      await prefsService.setScheduleEnabled(_scheduleEnabled);
      await prefsService.setScheduleHour(_scheduleTime.hour);
      await prefsService.setScheduleMinute(_scheduleTime.minute);
      await prefsService.setNotificationsEnabled(_notificationsEnabled);

      // Update background scheduling
      final scheduleUseCase = sl<ScheduleBriefingUseCase>();
      final scheduleParams = ScheduleBriefingParams(
        enabled: _scheduleEnabled,
        hour: _scheduleTime.hour,
        minute: _scheduleTime.minute,
        notificationsEnabled: _notificationsEnabled,
      );

      final result = await scheduleUseCase(scheduleParams);
      result.fold(
        (failure) {
          _showError('Failed to update schedule: ${failure.message}');
          return;
        },
        (success) {
          // Schedule updated successfully
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_scheduleEnabled
            ? 'Preferences saved! Daily briefing scheduled for ${_scheduleTime.format(context)}'
            : 'Preferences saved! Daily briefing schedule disabled'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      _showError('Failed to save preferences: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
