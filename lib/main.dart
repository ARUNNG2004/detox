import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/schedule_service.dart';

void main() async {
  // Ensure Flutter bindings are initialized before calling async code
  WidgetsFlutterBinding.ensureInitialized();

  // Create the single instance of ScheduleService
  final scheduleService = ScheduleService();
  // Load any saved schedule *before* running the app
  await scheduleService.loadSchedule();

  // Run the app, providing the ScheduleService instance
  runApp(DigitalDetoxApp(scheduleService: scheduleService));
}

class DigitalDetoxApp extends StatelessWidget {
  final ScheduleService scheduleService;

  // Constructor requires the pre-loaded service instance
  const DigitalDetoxApp({super.key, required this.scheduleService});

  @override
  Widget build(BuildContext context) {
    // Use MultiProvider in case you add more providers later
    return MultiProvider(
      providers: [
        // Provide the existing ScheduleService instance to the widget tree
        ChangeNotifierProvider<ScheduleService>.value(value: scheduleService),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false, // Hide debug banner
        title: 'Digital Detox',
        theme: ThemeData(
          primarySwatch: Colors.indigo, // Base theme color
          scaffoldBackgroundColor: Colors.grey[50], // Light background
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.indigo[700], // AppBar color
            foregroundColor: Colors.white, // AppBar text/icon color
            elevation: 2.0,
            centerTitle: true,
            titleTextStyle: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w500, letterSpacing: 0.5
            ),
          ),
          // Define default style for ElevatedButton
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo, // Button background
                foregroundColor: Colors.white, // Button text/icon color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Rounded buttons
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                elevation: 2,
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)
            ),
          ),
          // Define default style for TextButton
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Colors.indigo[600], // Text button color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          // Define default transition for screen navigation
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          ),
          useMaterial3: true,
        ),
        // Set the HomeScreen as the initial route
        home: const HomeScreen(),
      ),
    );
  }
}