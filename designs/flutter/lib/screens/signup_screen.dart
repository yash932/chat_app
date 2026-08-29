import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import 'chat_list_screen.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

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
                  Text('Create your account', style: AppTypography.title(c.ink)),
                  const SizedBox(height: 4),
                  Text('It takes less than a minute.', style: AppTypography.caption(c.inkSecondary)),
                  const SizedBox(height: 32),
                  const AppTextField(label: 'Full name', hint: 'Jordan Lee'),
                  const AppTextField(label: 'Email', hint: 'you@example.com', keyboardType: TextInputType.emailAddress),
                  const AppTextField(label: 'Password', hint: 'At least 8 characters', obscureText: true),
                  const SizedBox(height: 8),
                  AppButton(
                    label: 'Create account',
                    fullWidth: true,
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const ChatListScreen()),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? ', style: AppTypography.body(c.inkSecondary)),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Text('Log in', style: AppTypography.bodyStrong(c.cobalt)),
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
