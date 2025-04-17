import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BlackoutLockScreen extends StatefulWidget {
  final Duration duration;

  const BlackoutLockScreen({super.key, required this.duration});

  @override
  State<BlackoutLockScreen> createState() => _BlackoutLockScreenState();
}

class _BlackoutLockScreenState extends State<BlackoutLockScreen> {
  late Duration _remaining;
  Timer? _timer;
  bool _popped = false; // Prevent multiple pops

  @override
  void initState() {
    super.initState();
    _remaining = widget.duration.isNegative ? Duration.zero : widget.duration;

    // Enter immersive mode to hide status and navigation bars.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    if (_remaining > Duration.zero) {
      _startTimer();
    } else {
      // If duration is zero or less, pop immediately after build
      WidgetsBinding.instance.addPostFrameCallback((_) => _popScreen());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Restore the system UI mode *only if* screen hasn't been popped yet
    if (!_popped) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  void _popScreen() {
    // Ensure pop happens only once and the widget is still mounted
    if (!_popped && mounted) {
      _popped = true;
      // Restore UI *before* popping (safer)
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      Navigator.pop(context);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _timer?.cancel();
        return;
      }
      final newRemaining = _remaining - const Duration(seconds: 1);
      if (newRemaining.isNegative || newRemaining == Duration.zero) {
        _timer?.cancel();
        // Update state to show 00:00:00 before popping
        if(mounted) {
          setState(() { _remaining = Duration.zero; });
        }
        _popScreen(); // Exit screen when timer ends.
      } else {
        if(mounted) {
          setState(() { _remaining = newRemaining; });
        }
      }
    });
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return "00:00:00";
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  // Prevent back button exit
  Future<bool> _preventExit() async {
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = _formatDuration(_remaining);

    return WillPopScope(
      onWillPop: _preventExit, // Prevent back button exit.
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'DEVICE LOCKED',
                style: TextStyle(
                  color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.1,
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .shimmer(delay: 400.ms, duration: 1800.ms, color: Colors.grey[900])
                  .animate()
                  .fadeIn(duration: 600.ms, curve: Curves.easeOut),

              const SizedBox(height: 40),

              // AnimatedSwitcher for the timer text
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero)
                          .animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  formattedTime,
                  key: ValueKey<String>(formattedTime), // Key for switcher
                  style: const TextStyle(
                    color: Colors.white, fontSize: 64, fontWeight: FontWeight.w300, fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Until Unlock',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              )
                  .animate().fade(delay: 300.ms),
            ],
          ),
        ),
      ),
    );
  }
}