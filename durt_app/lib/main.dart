// In main.dart
import 'package:flutter/material.dart';
import 'screens/calendar_screen.dart'; // Import your new file
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
void main() {
  initializeDateFormatting('tr_TR', null).then((_) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dürt Uygulaması',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
      ),
      // --- İŞTE HATAYI ÇÖZEN KISIM BURASI ---
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'), // Türkçe desteği
        Locale('en', 'US'),
      ],
      // --------------------------------------
      home: const CalendarScreen(),
    );
  }
}