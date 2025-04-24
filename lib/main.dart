import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/schedule_service.dart';

void main() {
  runApp(const DigitalDetoxApp());
}

class DigitalDetoxApp extends StatelessWidget {
  const DigitalDetoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScheduleService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Digital Detox',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          scaffoldBackgroundColor: Colors.white,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
