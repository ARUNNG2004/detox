import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // For date/time formatting
import '../detox_service.dart'; // Import the platform channel wrapper
import 'blackout_screen.dart'; // Keep for navigation later

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isLoading = false;
  bool _overlayPermissionGranted = false;
  bool _accessibilityServiceEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadInitialTimes();
    _checkPermissions();
    // TODO: Consider if periodic check is still needed or if BlackoutScreen handles duration
  }

  Future<void> _loadInitialTimes() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final startTimeMillis = prefs.getInt('startTimeMillis');
    final endTimeMillis = prefs.getInt('endTimeMillis');

    if (startTimeMillis != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
      _startTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
    }
    if (endTimeMillis != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(endTimeMillis);
      _endTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkPermissions({bool showLoading = true}) async {
    if (showLoading && mounted) setState(() => _isLoading = true);
    _overlayPermissionGranted = await DetoxService.isOverlayPermissionGranted();
    _accessibilityServiceEnabled = await DetoxService.isAccessibilityServiceEnabled();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? (_startTime ?? TimeOfDay.now()) : (_endTime ?? TimeOfDay.now()),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _saveTimesAndStartDetox() async {
    if (_startTime == null || _endTime == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both start and end times.')),
      );
      return;
    }

    final now = DateTime.now();
    final startDateTime = DateTime(now.year, now.month, now.day, _startTime!.hour, _startTime!.minute);
    DateTime endDateTime = DateTime(now.year, now.month, now.day, _endTime!.hour, _endTime!.minute);

    // Handle end time crossing midnight
    if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
      endDateTime = endDateTime.add(const Duration(days: 1));
    }

    // Check permissions again before starting
    await _checkPermissions(showLoading: true);
    if (!_overlayPermissionGranted || !_accessibilityServiceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please grant Overlay and Accessibility permissions first.')),
      );
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('startTimeMillis', startDateTime.millisecondsSinceEpoch);
    await prefs.setInt('endTimeMillis', endDateTime.millisecondsSinceEpoch);
    await prefs.setBool('flutter.isDetoxActive', true); // For BootReceiver

    try {
      await DetoxService.startDetoxService();
      await DetoxService.setBlockingActive(true);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => BlackoutScreen(endTime: endDateTime)),
      );

    } catch (e) {
      print('Error starting detox: $e');
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error starting detox: $e')),
         );
      }
      // Clear active state if start failed
      await prefs.setBool('flutter.isDetoxActive', false);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Not Set';
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt); // Format like '5:08 PM'
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detox Setup'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text('Select Detox Period', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Start Time'),
                          TextButton(
                            onPressed: () => _selectTime(context, true),
                            child: Text(_formatTime(_startTime), style: Theme.of(context).textTheme.titleLarge),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('End Time'),
                          TextButton(
                            onPressed: () => _selectTime(context, false),
                            child: Text(_formatTime(_endTime), style: Theme.of(context).textTheme.titleLarge),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text('Permissions Status:', style: Theme.of(context).textTheme.titleMedium),
                  ListTile(
                    title: const Text('Overlay Permission'),
                    subtitle: Text(_overlayPermissionGranted ? 'Granted' : 'Required'),
                    trailing: Icon(
                      _overlayPermissionGranted ? Icons.check_circle : Icons.warning_amber_rounded,
                      color: _overlayPermissionGranted ? Colors.green : Colors.orange,
                    ),
                    onTap: !_overlayPermissionGranted ? () async {
                      try {
                        await DetoxService.requestOverlayPermission();
                        // Add a slight delay before checking the permission status
                        await Future.delayed(const Duration(milliseconds: 500));
                        await _checkPermissions(showLoading: false);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to request permission: $e')),
                          );
                        }
                      }
                    } : null,
                  ),
                  ListTile(
                    title: const Text('Accessibility Service'),
                     subtitle: Text(_accessibilityServiceEnabled ? 'Enabled' : 'Required'),
                    trailing: Icon(
                      _accessibilityServiceEnabled ? Icons.check_circle : Icons.warning_amber_rounded,
                      color: _accessibilityServiceEnabled ? Colors.green : Colors.orange,
                    ),
                     onTap: !_accessibilityServiceEnabled ? () async {
                        await DetoxService.requestAccessibilityPermission();
                        // Re-check after user returns from settings
                        Future.delayed(const Duration(seconds: 1), () => _checkPermissions(showLoading: false));
                     } : null,
                  ),
                   const SizedBox(height: 10),
                  if (!_overlayPermissionGranted || !_accessibilityServiceEnabled)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Tap required permission items above to grant access via system settings. The app needs these to function correctly.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.orange[800]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: (_startTime != null && _endTime != null && _overlayPermissionGranted && _accessibilityServiceEnabled) ? _saveTimesAndStartDetox : null,
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: (_startTime != null && _endTime != null && _overlayPermissionGranted && _accessibilityServiceEnabled) ? Theme.of(context).primaryColor : Colors.grey,
                    ),
                    child: const Text('Start Detox Session'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
      ),
    );
  }
}
