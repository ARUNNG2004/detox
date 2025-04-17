import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScheduleService with ChangeNotifier {
  TimeOfDay? _start;
  TimeOfDay? _end;
  bool _isBlackoutActive = false;
  Timer? _checkTimer;
  bool _isQuickSet = false;

  TimeOfDay? get start => _start;
  TimeOfDay? get end => _end;
  bool get isBlackoutActive => _isBlackoutActive;
  bool get isQuickSet => _isQuickSet;

  ScheduleService() {
    _init();
  }

  void _init() async {
    await loadSchedule();
    _startTimer();
  }

  Future<void> loadSchedule() async {
    _start = null;
    _end = null;
    _isQuickSet = false;
    _isBlackoutActive = false;

    try {
      final prefs = await SharedPreferences.getInstance();
      int? startHour = prefs.getInt('startHour');
      int? startMinute = prefs.getInt('startMinute');
      int? endHour = prefs.getInt('endHour');
      int? endMinute = prefs.getInt('endMinute');
      _isQuickSet = prefs.getBool('isQuickSet') ?? false;

      if (startHour != null && startMinute != null) {
        _start = TimeOfDay(hour: startHour, minute: startMinute);
      }
      if (endHour != null && endMinute != null) {
        _end = TimeOfDay(hour: endHour, minute: endMinute);
      }
      if (_start != null && _end != null) {
        _checkBlackoutStatus(notify: false);
      }
    } catch (e) {
      print("Error loading schedule: $e");
      _start = null; _end = null; _isQuickSet = false; _isBlackoutActive = false;
    } finally {
      notifyListeners();
    }
  }

  Future<void> saveSchedule(TimeOfDay start, TimeOfDay end, {bool isQuickSet = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('startHour', start.hour);
    await prefs.setInt('startMinute', start.minute);
    await prefs.setInt('endHour', end.hour);
    await prefs.setInt('endMinute', end.minute);
    await prefs.setBool('isQuickSet', isQuickSet);

    _start = start;
    _end = end;
    _isQuickSet = isQuickSet;
    _checkBlackoutStatus(notify: true); // Check and notify
  }

  Future<void> clearSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('startHour');
    await prefs.remove('startMinute');
    await prefs.remove('endHour');
    await prefs.remove('endMinute');
    await prefs.remove('isQuickSet');

    _start = null;
    _end = null;
    _isQuickSet = false;
    if (_isBlackoutActive) {
      _isBlackoutActive = false;
      notifyListeners();
    }
  }

  void _startTimer() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkBlackoutStatus(notify: true);
    });
  }

  void _checkBlackoutStatus({bool notify = true}) {
    if (_start == null || _end == null) {
      if (_isBlackoutActive) {
        _isBlackoutActive = false;
        if (notify) notifyListeners();
      }
      return;
    }

    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = _start!.hour * 60 + _start!.minute;
    final endMinutes = _end!.hour * 60 + _end!.minute;

    bool shouldBeActive;
    if (startMinutes == endMinutes) {
      shouldBeActive = false;
    } else if (startMinutes < endMinutes) {
      shouldBeActive = nowMinutes >= startMinutes && nowMinutes < endMinutes;
    } else {
      shouldBeActive = nowMinutes >= startMinutes || nowMinutes < endMinutes;
    }

    if (shouldBeActive != _isBlackoutActive) {
      _isBlackoutActive = shouldBeActive;
      if (notify) notifyListeners();
      if (!_isBlackoutActive && _isQuickSet) {
        Future.delayed(const Duration(milliseconds: 50), clearSchedule);
      }
    } else if (_isBlackoutActive && !shouldBeActive) {
      _isBlackoutActive = false;
      if (notify) notifyListeners();
      if (_isQuickSet) {
        Future.delayed(const Duration(milliseconds: 50), clearSchedule);
      }
    }
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }
}