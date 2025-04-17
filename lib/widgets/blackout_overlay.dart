import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Import flutter_animate
import '../services/schedule_service.dart';

class BlackoutOverlay extends StatefulWidget {
  const BlackoutOverlay({super.key});

  @override
  State<BlackoutOverlay> createState() => _BlackoutOverlayState();
}

class _BlackoutOverlayState extends State<BlackoutOverlay> {
  Duration _remaining = Duration.zero;
  Timer? _timer;
// In lib/widgets/blackout_overlay.dart -> _BlackoutOverlayState
  @override
  void initState() {
    super.initState();
    // --- Enter Full Screen Immersive Mode ---
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky); // This is the correct mode
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    // --- Exit Full Screen Mode ---
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge); // Restore UI on exit
    super.dispose();
  }
  void _startTimer() {
    _timer?.cancel();
    final schedule = context.read<ScheduleService>();
    _updateRemainingTime(schedule); // Initial update

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _timer?.cancel();
        return;
      }
      _updateRemainingTime(context.read<ScheduleService>());
    });
  }

  void _updateRemainingTime(ScheduleService schedule) {
    if (schedule.end == null) {
      if (mounted && _remaining != Duration.zero) {
        setState(() => _remaining = Duration.zero);
      }
      return;
    }

    final now = DateTime.now();
    final end = schedule.end!;
    DateTime endDt = DateTime(now.year, now.month, now.day, end.hour, end.minute);

    bool isOvernight = schedule.start != null &&
        (schedule.start!.hour * 60 + schedule.start!.minute) > (end.hour * 60 + end.minute);

    if (isOvernight && endDt.isBefore(now)) {
      endDt = endDt.add(const Duration(days: 1));
    }
    else if (!isOvernight && endDt.isBefore(now)) {
      if (mounted && _remaining != Duration.zero) {
        setState(() => _remaining = Duration.zero);
      }
      return;
    }

    Duration newRemaining = endDt.isAfter(now) ? endDt.difference(now) : Duration.zero;

    // Optimize setState calls: Only update if the remaining seconds have changed
    // Use inSeconds comparison which is reliable for timer updates
    if (mounted && newRemaining.inSeconds != _remaining.inSeconds) {
      setState(() {
        _remaining = newRemaining;
      });
    }
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return "00:00:00";
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    // Format the time *before* the AnimatedSwitcher
    final formattedTime = _formatDuration(_remaining);

    return Material(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'DIGITAL DETOX ACTIVE',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            )
            // Add a subtle pulse animation to the title
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .tint(color: Colors.indigo.shade100, duration: 3000.ms, end: 0.1) // Subtle tint pulse
                .then(delay: 1500.ms), // Pause between pulses

            const SizedBox(height: 60),

            // --- Animated Timer Text ---
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400), // Animation duration for text change
              transitionBuilder: (Widget child, Animation<double> animation) {
                // Slide + Fade transition for the numbers
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.3), // Start slightly below
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              // Use the formatted time string itself as the key.
              // When the string changes, the switcher animates.
              child: Text(
                formattedTime,
                key: ValueKey<String>(formattedTime), // Essential for AnimatedSwitcher
                style: const TextStyle(
                  fontSize: 72,
                  color: Colors.white,
                  fontWeight: FontWeight.w300,
                  // Consider using a specific font for the timer if you added one
                  // fontFamily: 'Orbitron',
                  fontFamily: 'monospace',
                ),
              ),
            ),
            // --- End Animated Timer Text ---

            const SizedBox(height: 20),
            const Text(
              'Time Remaining',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            )
            // Fade in the label slightly after the title
                .animate().fade(delay: 500.ms),
          ],
        ),
      ),
    )
    // Add a subtle overall animation to the overlay content
        .animate()
        .fade(duration: 600.ms); // Fade in the entire overlay content
  }
}