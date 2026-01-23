// In main.dart
import 'package:flutter/material.dart';
import 'screens/calendar_screen.dart'; // Import your new file
import 'package:intl/date_symbol_data_local.dart';
void main() {
  initializeDateFormatting('tr_TR', null).then((_) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Durt App',
      theme: ThemeData(primarySwatch: Colors.red),
      home: const CalendarScreen(), // Set the calendar as the home screen
    );
  }
}