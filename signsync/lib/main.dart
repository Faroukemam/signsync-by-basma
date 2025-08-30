import 'package:flutter/material.dart';
import 'package:signsync/screens/SplashScreen.dart';
import 'package:signsync/screens/homepage.dart';
import 'package:signsync/screens/chat_screen.dart';

void main() {
  runApp(const SignSyncApp());
}

/// Root app widget for SignSync.
class SignSyncApp extends StatelessWidget {
  const SignSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SignSync',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff585123)),
        useMaterial3: true,
      ),
      // Splash routes to HomePage after a short delay.
      home: const SplashScreen(),
      routes: {
        '/home': (context) => const HomePage(),
        // Simple demo route to the chat screen with default contact info.
        '/chat': (context) => const ChatScreen(
              title: 'Support',
              subtitle: 'online',
            ),
      },
    );
  }
}

/// Optional alias to satisfy default Flutter test templates that expect `MyApp`.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => const SignSyncApp();
}

