import 'package:flutter/material.dart';

class EmergencyExit extends StatelessWidget {
  const EmergencyExit({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Implement the secret emergency exit gesture or button
        _triggerEmergencyExit(context);
      },
      child: const Positioned(
        top: 0,
        right: 0,
        child: Icon(
          Icons.warning_amber_rounded,
          size: 50,
          color: Colors.red,
        ),
      ),
    );
  }

  void _triggerEmergencyExit(BuildContext context) {
    // You can implement an authentication mechanism here (e.g., pin or fingerprint)
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Emergency Exit"),
          content: const Text("Are you sure you want to end the blackout?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);  // Close dialog
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                // You can end the blackout immediately here if needed
                Navigator.pop(context);
                // Handle emergency logic (e.g., end blackout, show alert, etc.)
              },
              child: const Text("Exit Now"),
            ),
          ],
        );
      },
    );
  }
}
