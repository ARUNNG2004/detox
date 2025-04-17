import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/schedule_service.dart';
import 'schedule_screen.dart';
import '../widgets/blackout_lock_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _isLockScreenPresented = false;
  VoidCallback? _scheduleListener;
  ScheduleService? _scheduleServiceInstance;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final scheduleService = context.read<ScheduleService>();
        if (scheduleService.isBlackoutActive && !_isLockScreenPresented) {
          _navigateToLockScreen(scheduleService);
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scheduleService = Provider.of<ScheduleService>(context, listen: false);
    if (scheduleService != _scheduleServiceInstance || _scheduleListener == null) {
      if (_scheduleServiceInstance != null && _scheduleListener != null) {
        _scheduleServiceInstance!.removeListener(_scheduleListener!);
      }
      _scheduleServiceInstance = scheduleService;
      _scheduleListener = () {
        if (!mounted) return;
        final bool isActive = _scheduleServiceInstance!.isBlackoutActive;
        print("Listener: isActive = $isActive, isPresented = $_isLockScreenPresented"); // Debug
        if (isActive && !_isLockScreenPresented) {
          _navigateToLockScreen(_scheduleServiceInstance!);
        } else if (!isActive && _isLockScreenPresented) {
          // Reset flag if state becomes inactive externally. Pop is handled by LockScreen / .then()
          setState(() { _isLockScreenPresented = false; });
        }
      };
      _scheduleServiceInstance!.addListener(_scheduleListener!);
    }
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_scheduleServiceInstance != null && _scheduleListener != null) {
      _scheduleServiceInstance!.removeListener(_scheduleListener!);
    }
    _scheduleListener = null;
    _scheduleServiceInstance = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      final scheduleService = context.read<ScheduleService>();
      final bool isActive = scheduleService.isBlackoutActive;
      if (isActive && !_isLockScreenPresented) {
        _navigateToLockScreen(scheduleService);
      }
    }
  }

  void _navigateToLockScreen(ScheduleService schedule) {
    if (!mounted || _isLockScreenPresented) return;
    setState(() { _isLockScreenPresented = true; });
    final Duration remainingDuration = _calculateRemainingDuration(schedule);
    print("Navigating to Lock Screen. Duration: $remainingDuration"); // Debug
    Navigator.push( context,
      MaterialPageRoute( builder: (context) => BlackoutLockScreen(duration: remainingDuration)),
    ).then((_) {
      print("Returned from Lock Screen"); // Debug
      if (mounted) { setState(() { _isLockScreenPresented = false; }); }
    });
  }

  Duration _calculateRemainingDuration(ScheduleService schedule) {
    if (schedule.end == null) return Duration.zero;
    final now = DateTime.now();
    final end = schedule.end!;
    DateTime endDt = DateTime(now.year, now.month, now.day, end.hour, end.minute);
    bool isOvernight = schedule.start != null && (schedule.start!.hour * 60 + schedule.start!.minute) > (end.hour * 60 + end.minute);
    if (isOvernight && endDt.isBefore(now)) { endDt = endDt.add(const Duration(days: 1)); }
    else if (!isOvernight && endDt.isBefore(now)) { return Duration.zero; }
    return endDt.isAfter(now) ? endDt.difference(now) : Duration.zero;
  }

  void _navigateToScheduleScreen() {
    if (!_isLockScreenPresented) {
      Navigator.push( context, MaterialPageRoute(builder: (context) => const ScheduleScreen()));
    }
  }

  void _startQuickSet(Duration duration) {
    if (_isLockScreenPresented) return;
    final scheduleService = context.read<ScheduleService>();
    final now = DateTime.now();
    final startTime = TimeOfDay.fromDateTime(now);
    final endTime = TimeOfDay.fromDateTime(now.add(duration));
    scheduleService.saveSchedule(startTime, endTime, isQuickSet: true); // Listener will trigger navigation
    ScaffoldMessenger.of(context).showSnackBar( SnackBar(
      content: Text('Quick blackout requested for ${duration.inMinutes} min!'),
      duration: const Duration(seconds: 2), backgroundColor: Colors.blueGrey,
      behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final schedule = context.read<ScheduleService>();
    final manualStartTime = schedule.start;
    final manualEndTime = schedule.end;
    final isQuickSet = schedule.isQuickSet;
    final initialDelay = 200.ms;
    final itemInterval = 100.ms;

    return Scaffold(
      body: Stack(
        children: [
          Container( decoration: BoxDecoration( gradient: LinearGradient(
            colors: [Colors.indigo.shade50, Colors.grey.shade50],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ))),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.indigo[700]?.withOpacity(0.95), elevation: 0, title: const Text('Digital Detox'),
              actions: [ IconButton( icon: const Icon(Icons.timer_outlined), tooltip: 'Set Manual Schedule',
                onPressed: _navigateToScheduleScreen,
              ).animate().fade(delay: 500.ms).slideX(begin: 0.5),
              ],
            ),
            body: SafeArea( child: Padding( padding: const EdgeInsets.all(20.0),
              child: Column( mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (manualStartTime != null && manualEndTime != null && !isQuickSet)
                    Padding( padding: const EdgeInsets.only(bottom: 30.0),
                      child: Text( 'Manual Schedule:\n${manualStartTime.format(context)} - ${manualEndTime.format(context)}',
                        textAlign: TextAlign.center, style: TextStyle( fontSize: 16, color: Theme.of(context).primaryColorDark,
                          fontWeight: FontWeight.w500, height: 1.4,),
                      ),
                    ).animate().fade(delay: initialDelay).slideY(begin: 0.2)
                  else if (!isQuickSet)
                    const Padding( padding: EdgeInsets.only(bottom: 30.0),
                      child: Text( 'No manual schedule set.\nUse Quick Sets or tap ↗ to create one.',
                        textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.4),
                      ),
                    ).animate().fade(delay: initialDelay).slideY(begin: 0.2),
                  const Text('Start Quick Blackout', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600))
                      .animate().fade(delay: initialDelay + itemInterval).slideY(begin: 0.3),
                  const SizedBox(height: 10),
                  const Text('(Starts immediately)', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey))
                      .animate().fade(delay: initialDelay + itemInterval * 1.5).slideY(begin: 0.3),
                  const SizedBox(height: 30),
                  Wrap( spacing: 15.0, runSpacing: 15.0, alignment: WrapAlignment.center,
                    children: [
                      _buildQuickSetButton(const Duration(minutes: 1), '1 Min'),
                      _buildQuickSetButton(const Duration(minutes: 5), '5 Min'),
                      _buildQuickSetButton(const Duration(minutes: 10), '10 Min'),
                      _buildQuickSetButton(const Duration(minutes: 30), '30 Min'),
                      _buildQuickSetButton(const Duration(hours: 1), '1 Hour'),
                      _buildQuickSetButton(const Duration(hours: 3), '3 Hours'),
                      _buildQuickSetButton(const Duration(hours: 8), '8 Hours'),
                    ].animate(interval: itemInterval, delay: initialDelay + itemInterval * 2)
                        .fade(duration: 400.ms).slideY(begin: 0.5, duration: 400.ms, curve: Curves.easeOut),
                  ),
                  const Spacer(),
                ],
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSetButton(Duration duration, String label) {
    return ElevatedButton(
      onPressed: () => _startQuickSet(duration),
      child: Text(label),
    ).animate(target: 0.95, effects: [ScaleEffect(duration: 100.ms)]);
  }
}