import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const ChatUiKitApp());
}

/// Run this file to preview every screen in the kit: it opens on the
/// login screen — from there, sign in to reach the chat list, tap a
/// conversation to open it, and use the avatar / gear icons to reach
/// Profile and Settings (Settings includes a working dark-mode toggle).
class ChatUiKitApp extends StatelessWidget {
  const ChatUiKitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Chat UI Kit',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: const LoginScreen(),
        );
      },
    );
  }
}
