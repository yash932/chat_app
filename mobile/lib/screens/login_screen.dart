import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import 'signup_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  void _showServerConfigDialog() {
    final serverController = TextEditingController(text: ApiService.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.dns_rounded, size: 20),
            SizedBox(width: 8),
            Text('Server Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your backend server or tunnel URL:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: serverController,
              decoration: const InputDecoration(
                hintText: 'https://...loca.lt',
                labelText: 'Server URL',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUrl = serverController.text.trim();
              if (newUrl.isNotEmpty) {
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(ctx);
                await Provider.of<ChatProvider>(context, listen: false).updateServerUrl(newUrl);
                if (!mounted) return;
                nav.pop();
                messenger.showSnackBar(
                  SnackBar(content: Text('Server URL set to $newUrl')),
                );
                setState(() {});
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter both email/username and password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Provider.of<ChatProvider>(context, listen: false).login(email, password);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (err) {
      setState(() {
        _isLoading = false;
        _errorMessage = err.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppSemanticColors>()!;

    return Scaffold(
      backgroundColor: c.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Server Settings',
            icon: Icon(Icons.dns_rounded, color: c.inkSecondary, size: 20),
            onPressed: _showServerConfigDialog,
          ),
        ],
      ),
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
                    decoration: BoxDecoration(
                      color: c.cobalt,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.chat_bubble, color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 20),
                  Text('Welcome back', style: AppTypography.title(c.ink)),
                  const SizedBox(height: 4),
                  Text(
                    'Log in to keep the conversation going.',
                    style: AppTypography.caption(c.inkSecondary),
                  ),
                  const SizedBox(height: 32),
                  AppTextField(
                    label: 'Email or Username',
                    hint: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                    controller: _emailController,
                  ),
                  AppTextField(
                    label: 'Password',
                    hint: '••••••••',
                    obscureText: true,
                    controller: _passwordController,
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14.0),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: c.coral, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  AppButton(
                    label: 'Log in',
                    fullWidth: true,
                    isLoading: _isLoading,
                    onPressed: _handleLogin,
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
                  const SizedBox(height: 16),
                  TextButton.icon(
                    icon: Icon(Icons.link, size: 14, color: c.inkSecondary),
                    label: Text(
                      'Server: ${ApiService.baseUrl}',
                      style: TextStyle(fontSize: 11, color: c.inkSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: _showServerConfigDialog,
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
