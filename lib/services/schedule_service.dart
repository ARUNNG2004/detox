import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScheduleService with ChangeNotifier {
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isDetoxActive = false;

  TimeOfDay? get startTime => _startTime;
  TimeOfDay? get endTime => _endTime;
  bool get isDetoxActive => _isDetoxActive;

  void setStartTime(TimeOfDay time) {
    _startTime = time;
    saveTimes();
    notifyListeners();
  }

  void setEndTime(TimeOfDay time) {
    _endTime = time;
    saveTimes();
    notifyListeners();
  }

  void activateDetox() {
    _isDetoxActive = true;
    notifyListeners();
  }

  void deactivateDetox() {
    _isDetoxActive = false;
    notifyListeners();
  }

  Future<void> saveTimes() async {
    final prefs = await SharedPreferences.getInstance();
    if (_startTime != null) {
      prefs.setInt('start_hour', _startTime!.hour);
      prefs.setInt('start_minute', _startTime!.minute);
    }
    if (_endTime != null) {
      prefs.setInt('end_hour', _endTime!.hour);
      prefs.setInt('end_minute', _endTime!.minute);
    }
  }

  Future<void> loadTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final startHour = prefs.getInt('start_hour');
    final startMinute = prefs.getInt('start_minute');
    final endHour = prefs.getInt('end_hour');
    final endMinute = prefs.getInt('end_minute');

    if (startHour != null && startMinute != null) {
      _startTime = TimeOfDay(hour: startHour, minute: startMinute);
    }
    if (endHour != null && endMinute != null) {
      _endTime = TimeOfDay(hour: endHour, minute: endMinute);
    }
    notifyListeners();
  }
}
