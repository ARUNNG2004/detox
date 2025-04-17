import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/schedule_service.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    final scheduleService = context.read<ScheduleService>();
    _startTime = scheduleService.start;
    _endTime = scheduleService.end;
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay initialTime = isStart
        ? (_startTime ?? TimeOfDay.now())
        : (_endTime ?? TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1))));

    final TimeOfDay? picked = await showTimePicker(
      context: context, initialTime: initialTime, helpText: isStart ? 'SELECT START TIME' : 'SELECT END TIME',
    );

    if (picked != null && mounted) {
      setState(() { if (isStart) _startTime = picked; else _endTime = picked; });
    }
  }

  void _saveScheduledTime() {
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar( SnackBar(
        content: const Text('Please select both a start and end time.'),
        backgroundColor: Colors.orangeAccent, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      )); return;
    }
    final scheduleService = context.read<ScheduleService>();
    scheduleService.saveSchedule(_startTime!, _endTime!, isQuickSet: false);
    ScaffoldMessenger.of(context).showSnackBar( SnackBar(
      content: const Text('Manual schedule saved!'), backgroundColor: Colors.green[600],
      behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
    if (mounted) Navigator.pop(context);
  }

  void _clearSchedule() {
    final scheduleService = context.read<ScheduleService>();
    scheduleService.clearSchedule();
    if(mounted) {
      setState(() { _startTime = null; _endTime = null; });
    }
    ScaffoldMessenger.of(context).showSnackBar( SnackBar(
      content: const Text('Manual schedule cleared.'), behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Widget _buildTimeTile(String label, TimeOfDay? time, bool isStart) {
    return ListTile(
      leading: Icon(Icons.access_time, color: Theme.of(context).primaryColor),
      title: Text(label),
      trailing: Text( time == null ? 'Not Set' : time.format(context),
        style: TextStyle( fontSize: 16, fontWeight: time == null ? FontWeight.normal : FontWeight.bold,
            color: time == null ? Colors.grey : Colors.black87),
      ),
      onTap: () => _selectTime(context, isStart),
      shape: RoundedRectangleBorder( side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
      tileColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialDelay = 150.ms;
    final itemInterval = 100.ms;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Set Manual Schedule"),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text( "Define a recurring daily blackout period.",
              style: TextStyle(fontSize: 16, color: Colors.black54), textAlign: TextAlign.center,
            ).animate().fade(delay: initialDelay).slideY(begin: 0.2),
            const SizedBox(height: 30),
            _buildTimeTile("Start Time", _startTime, true)
                .animate().fade(delay: initialDelay + itemInterval).slideX(begin: -0.2),
            const SizedBox(height: 20),
            _buildTimeTile("End Time", _endTime, false)
                .animate().fade(delay: initialDelay + itemInterval * 2).slideX(begin: -0.2),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.save_alt_outlined), label: const Text("Save Manual Schedule"),
              onPressed: _saveScheduledTime, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
            ).animate().fade(delay: initialDelay + itemInterval * 3).slideY(begin: 0.3),
            const SizedBox(height: 15),
            TextButton.icon(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
              label: const Text("Clear Manual Schedule", style: TextStyle(color: Colors.redAccent)),
              onPressed: _clearSchedule, style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
            ).animate().fade(delay: initialDelay + itemInterval * 4).slideY(begin: 0.3),
            const Spacer(),
            const Padding( padding: EdgeInsets.only(bottom: 8.0),
              child: Text( "Note: Saving a manual schedule will override any active quick set.",
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ).animate().fade(delay: initialDelay + itemInterval * 5),
          ],
        ),
      ),
    );
  }
}