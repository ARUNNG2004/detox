import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For SystemUiMode
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../detox_service.dart';
import 'home_screen.dart'; // To navigate back

class BlackoutScreen extends StatefulWidget {
  final DateTime endTime;

  const BlackoutScreen({super.key, required this.endTime});

  @override
  State<BlackoutScreen> createState() => _BlackoutScreenState();
}

class _BlackoutScreenState extends State<BlackoutScreen> with WidgetsBindingObserver {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateRemainingTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemainingTime();
    });

    // Start all protection mechanisms
    _initializeProtection();
  }

  Future<void> _initializeProtection() async {
    // Ensure blocking is active
    await DetoxService.setBlockingActive(true);

    // Start screen pinning
    await DetoxService.startScreenPinning();

    // Enter immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-apply immersive mode if the app resumes
    if (state == AppLifecycleState.resumed) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  void _updateRemainingTime() {
    final now = DateTime.now();
    if (mounted && now.isBefore(widget.endTime)) {
      setState(() {
        _remainingTime = widget.endTime.difference(now);
      });
    } else {
      _stopDetoxSession(sessionEndedNormally: true);
    }
  }

  Future<void> _stopDetoxSession({bool sessionEndedNormally = false}) async {
    _timer?.cancel();

    // Stop screen pinning
    await DetoxService.stopScreenPinning();

    // Restore normal UI mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Stop the foreground service and disable accessibility blocking
    await DetoxService.stopDetoxService();
    await DetoxService.setBlockingActive(false);

    // Clear the active state flag
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('flutter.isDetoxActive', false);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    // Avoid showing negative duration if there's a slight delay
    if (duration.isNegative) return "00:00:00";
    return "$hours:$minutes:$seconds";
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    // Ensure UI mode is restored if screen is disposed unexpectedly
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // WillPopScope prevents back button navigation
    return WillPopScope(
      onWillPop: () async => false, // Disable back button
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatDuration(_remainingTime),
                style: const TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Detox session ends at ${DateFormat.jm().format(widget.endTime)}',
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
