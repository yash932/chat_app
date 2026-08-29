import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import 'signup_screen.dart';
import 'chat_list_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppSemanticColors>()!;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: c.cobalt, borderRadius: BorderRadius.circular(12)),
                  ),
                  const SizedBox(height: 20),
                  Text('Welcome back', style: AppTypography.title(c.ink)),
                  const SizedBox(height: 4),
                  Text(
                    'Log in to keep the conversation going.',
                    style: AppTypography.caption(c.inkSecondary),
                  ),
                  const SizedBox(height: 32),
                  const AppTextField(label: 'Email', hint: 'you@example.com', keyboardType: TextInputType.emailAddress),
                  const AppTextField(label: 'Password', hint: '••••••••', obscureText: true),
                  const SizedBox(height: 8),
                  AppButton(
                    label: 'Log in',
                    fullWidth: true,
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const ChatListScreen()),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? ", style: AppTypography.body(c.inkSecondary)),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SignupScreen()),
                        ),
                        child: Text('Sign up', style: AppTypography.bodyStrong(c.cobalt)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
