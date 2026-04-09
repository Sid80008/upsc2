import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/auth_service.dart';
import 'onboarding_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  // Theme Colors (Matching Login)
  static const Color primary = Color(0xFF005AAB);
  static const Color primaryContainer = Color(0xFF1173D4);
  static const Color secondary = Color(0xFF515F74);
  static const Color surface = Color(0xFFF7F9FB);
  static const Color onSurface = Color(0xFF191C1E);
  static const Color surfaceContainerLow = Color(0xFFF2F4F6);
  static const Color outlineVariant = Color(0xFFC1C6D4);
  static const Color onPrimary = Color(0xFFFFFFFF);

  void _signup() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Show hint that server may be slow on first connection
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Connecting to server... This may take up to 60 seconds on first use.'),
        duration: Duration(seconds: 8),
        backgroundColor: Color(0xFF1173D4),
      ),
    );

    final error = await _authService.signup(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
    );
    
    if (error == null) {
      // Signup succeeded — now login
      final loginSuccess = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      setState(() => _isLoading = false);
      if (loginSuccess && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          (route) => false
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created! Please log in manually.')),
        );
        Navigator.pop(context); // Go back to login screen
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            duration: const Duration(seconds: 6),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surface,
      body: Stack(
        children: [
          // Background Gradients
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-1.0, -1.0),
                  radius: 1.5,
                  colors: [Color(0x0D1173D4), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(1.0, 1.0),
                  radius: 1.5,
                  colors: [Color(0x0D006847), Colors.transparent],
                ),
              ),
            ),
          ),
          
          // Floating Background Icons
          _buildFloatingIcon(Icons.auto_stories, top: 0.1, left: 0.15, size: 64),
          _buildFloatingIcon(Icons.architecture, bottom: 0.15, left: 0.1, size: 80),
          _buildFloatingIcon(Icons.edit_note, top: 0.2, right: 0.1, size: 72),
          _buildFloatingIcon(Icons.school, bottom: 0.2, right: 0.2, size: 56),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand Header
                    const Text(
                      'UPSC ARCHITECT',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 6,
                        color: primaryContainer,
                        fontFamily: 'Lexend',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Designing your path to civil service.',
                      style: TextStyle(
                        color: secondary,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Signup Card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                            boxShadow: [
                              BoxShadow(
                                color: onSurface.withValues(alpha:0.06),
                                blurRadius: 32,
                                offset: const Offset(0, 12),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Center(
                                child: Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Lexend',
                                    color: onSurface,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              
                              // Name Field
                              const Text(
                                'FULL NAME',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                  color: secondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _nameController,
                                icon: Icons.person_outline,
                                hint: 'John Doe',
                              ),
                              const SizedBox(height: 20),

                              // Email Field
                              const Text(
                                'EMAIL ADDRESS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                  color: secondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _emailController,
                                icon: Icons.mail_outline,
                                hint: 'name@domain.com',
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 20),

                              // Password Field
                              const Text(
                                'PASSWORD',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                  color: secondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _passwordController,
                                icon: Icons.lock_outline,
                                hint: '••••••••',
                                obscureText: true,
                              ),
                              const SizedBox(height: 32),

                              // Sign Up Action
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _signup,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    foregroundColor: onPrimary,
                                    elevation: 8,
                                    shadowColor: primary.withValues(alpha: 0.3),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: onPrimary, strokeWidth: 2))
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text('Get Started', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Lexend')),
                                            SizedBox(width: 8),
                                            Icon(Icons.arrow_forward, size: 20),
                                          ],
                                        ),
                                ),
                              ),

                              const SizedBox(height: 32),
                              
                              // Divider
                              Row(
                                children: [
                                  Expanded(child: Divider(color: outlineVariant.withValues(alpha: 0.2))),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16),
                                    child: Text('OR JOIN WITH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                                  ),
                                  Expanded(child: Divider(color: outlineVariant.withValues(alpha: 0.2))),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Social Logins
                              Row(
                                children: [
                                  Expanded(child: _buildSocialBtn('Google', 'https://lh3.googleusercontent.com/aida-public/AB6AXuA0cLOsbP0XHaltx3IXH7lPrP6ee7HJpIMqWiO-08MOhl3WD9yGDpmdGsbpHc1mQoukplYHZtEwd3o-_B0D1yCk8A7RofPTrqsIXMWfcT1A0TkdmVJeMVikHJc56DACzxv3Hcrkz1hqIBzpr73muniJcsiWQadA3Y8Au08Gg2qthNBa7GfXv-816r0VmMzR6Sb2On8UJj0tz7bYay_cz6b70YwcV24UCSPLRQNRKCFt6NMeFlW5avtX_g-QEmK5I4tuwJ4uGgWKCN0c')),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildSocialBtn('Apple', null, icon: Icons.apple)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Footer Action
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account?", style: TextStyle(color: secondary, fontWeight: FontWeight.w500)),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text("Sign In", style: TextStyle(color: primaryContainer, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: outlineVariant, size: 20),
          hintText: hint,
          hintStyle: const TextStyle(color: outlineVariant, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSocialBtn(String label, String? imageUrl, {IconData? icon}) {
    return InkWell(
      onTap: () {},
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: outlineVariant.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imageUrl != null)
              Image.network(imageUrl, width: 20, height: 20)
            else if (icon != null)
              Icon(icon, size: 24),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onSurface)),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingIcon(IconData icon, {double? top, double? bottom, double? left, double? right, required double size}) {
    return Positioned(
      top: top != null ? MediaQuery.of(context).size.height * top : null,
      bottom: bottom != null ? MediaQuery.of(context).size.height * bottom : null,
      left: left != null ? MediaQuery.of(context).size.width * left : null,
      right: right != null ? MediaQuery.of(context).size.width * right : null,
      child: Opacity(
        opacity: 0.05,
        child: Icon(icon, size: size, color: primaryContainer),
      ),
    );
  }
}
