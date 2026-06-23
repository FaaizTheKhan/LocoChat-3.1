import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/chat_state.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatState()),
      ],
      child: const LocoChatApp(),
    ),
  );
}

class LocoChatApp extends StatelessWidget {
  const LocoChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LocoChat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Deep Slate
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF38BDF8), // Light Blue
          secondary: const Color(0xFF818CF8), // Indigo
          surface: const Color(0xFF1E293B),
        ),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}
