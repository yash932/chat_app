import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/chat_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PulseChatApp());
}

class PulseChatApp extends StatelessWidget {
  const PulseChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ChatProvider()..initialize(),
        ),
      ],
      child: Consumer<ChatProvider>(
        builder: (context, chatProvider, _) {
          return MaterialApp(
            title: 'PulseChat',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: chatProvider.themeMode == 'light' ? ThemeMode.light : ThemeMode.dark,
            home: chatProvider.isLoggedIn ? const HomeScreen() : const LoginScreen(),
          );
        },
      ),
    );
  }
}
