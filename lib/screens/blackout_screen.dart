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
  int _tapCount = 0;
  Timer? _tapTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateRemainingTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemainingTime();
    });

    // Ensure blocking is active and UI is immersive
    DetoxService.setBlockingActive(true);
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
    _tapTimer?.cancel();

    // Restore normal UI mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Stop the foreground service and disable accessibility blocking
    await DetoxService.stopDetoxService();
    await DetoxService.setBlockingActive(false);

    // Clear the active state flag
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('flutter.isDetoxActive', false);

    // Navigate back to HomeScreen only if mounted
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
      if (!sessionEndedNormally) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Emergency exit activated.'), duration: Duration(seconds: 2)),
         );
      }
    }
  }

  void _handleTap() {
    _tapCount++;
    _tapTimer?.cancel(); // Cancel previous timer if taps are close

    if (_tapCount >= 5) {
      print("Emergency exit triggered!");
      _tapCount = 0;
      _stopDetoxSession(sessionEndedNormally: false);
    } else {
      // Reset tap count if taps are too far apart (e.g., > 2 seconds)
      _tapTimer = Timer(const Duration(seconds: 2), () {
        print("Tap timer expired, resetting count.");
        if (mounted) {
          setState(() {
            _tapCount = 0;
          });
        }
      });
    }
     // Debug print
     // print("Tap count: $_tapCount");
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
    _tapTimer?.cancel();
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
      child: GestureDetector(
        onTap: _handleTap, // Detect taps anywhere on the screen
        behavior: HitTestBehavior.opaque, // Ensure GestureDetector covers the whole screen
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
                    fontFeatures: [FontFeature.tabularFigures()], // Helps prevent text jumping
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Detox session ends at ${DateFormat.jm().format(widget.endTime)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
                 const SizedBox(height: 50),
                 const Text(
                  '(Tap 5 times rapidly for emergency exit)',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
