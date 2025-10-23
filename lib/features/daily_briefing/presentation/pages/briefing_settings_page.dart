import 'package:flutter/material.dart';

import '../../../../core/services/briefing_preferences_service.dart';
import '../../../../injection_container.dart' as di;

class BriefingSettingsPage extends StatefulWidget {
  const BriefingSettingsPage({super.key});

  @override
  State<BriefingSettingsPage> createState() => _BriefingSettingsPageState();
}

class _BriefingSettingsPageState extends State<BriefingSettingsPage> {
  final _prefsService = di.sl<BriefingPreferencesService>();
  final _cityController = TextEditingController();

  bool _useGps = true;
  bool _scheduleEnabled = false;
  bool _notificationsEnabled = true;
  TimeOfDay _scheduleTime = const TimeOfDay(hour: 7, minute: 0);
  final List<String> _selectedCategories = [];

  final List<String> _availableCategories = [
    'general',
    'business',
    'technology',
    'science',
    'health',
    'sports',
    'entertainment',
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() {
    setState(() {
      _useGps = _prefsService.useGps;
      _cityController.text = _prefsService.city;
      _scheduleEnabled = _prefsService.scheduleEnabled;
      _notificationsEnabled = _prefsService.notificationsEnabled;
      _scheduleTime = TimeOfDay(
        hour: _prefsService.scheduleHour,
        minute: _prefsService.scheduleMinute,
      );
      _selectedCategories.clear();
      _selectedCategories.addAll(_prefsService.newsCategories);
    });
  }

  Future<void> _savePreferences() async {
    await _prefsService.setUseGps(_useGps);
    await _prefsService.setCity(_cityController.text);
    await _prefsService.setScheduleEnabled(_scheduleEnabled);
    await _prefsService.setNotificationsEnabled(_notificationsEnabled);
    await _prefsService.setScheduleHour(_scheduleTime.hour);
    await _prefsService.setScheduleMinute(_scheduleTime.minute);
    await _prefsService.setNewsCategories(_selectedCategories);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully!')),
      );
      Navigator.pop(context, true); // Return true to indicate settings changed
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduleTime,
    );

    if (picked != null) {
      setState(() {
        _scheduleTime = picked;
      });
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Briefing Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _savePreferences,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Location Settings
          _buildSectionHeader('Location'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Use GPS Location'),
                  subtitle: const Text('Automatically detect your location'),
                  value: _useGps,
                  onChanged: (value) {
                    setState(() {
                      _useGps = value;
                    });
                  },
                ),
                if (!_useGps) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City Name',
                        hintText: 'Enter city name',
                        prefixIcon: Icon(Icons.location_city),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // News Preferences
          _buildSectionHeader('News Categories'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
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
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Schedule Settings
          _buildSectionHeader('Daily Schedule'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Morning Briefing'),
                  subtitle: const Text('Get daily briefing at scheduled time'),
                  value: _scheduleEnabled,
                  onChanged: (value) {
                    setState(() {
                      _scheduleEnabled = value;
                    });
                  },
                ),
                if (_scheduleEnabled) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.schedule),
                    title: const Text('Schedule Time'),
                    subtitle: Text(_scheduleTime.format(context)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _pickTime,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Notifications'),
                    subtitle: const Text('Show notification with briefing summary'),
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
          ),
          const SizedBox(height: 24),

          // Info Card
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Changes will take effect on next briefing refresh',
                      style: TextStyle(color: Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
