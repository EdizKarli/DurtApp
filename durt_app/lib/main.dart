import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(home: const MyHomePage());
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _displayText = "Press the button to call the backend";

  Future<void> fetchBackendData() async {
    // Since you are on Windows/Desktop, use 'localhost'
    final url = Uri.parse('http://localhost:3000/api/message');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _displayText = jsonDecode(response.body)['message'];
        });
      }
    } catch (e) {
      setState(() { _displayText = "Error: $e"; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("DurtApp Full Stack")),
      body: Center(child: Text(_displayText, style: const TextStyle(fontSize: 18))),
      floatingActionButton: FloatingActionButton(
        onPressed: fetchBackendData, // Triggers the Node.js call
        child: const Icon(Icons.download),
      ),
    );
  }
}