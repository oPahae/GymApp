// lib/screens/login.dart
import 'package:flutter/material.dart';
import 'package:test_hh/constants/colors.dart';
import 'package:test_hh/screens/register.dart';
import 'package:test_hh/screens/home.dart';
import 'package:test_hh/screens/forgotPassword.dart';
import 'package:test_hh/services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
  final identifier = _identifierController.text.trim();
  final password = _passwordController.text;

  if (identifier.isEmpty || password.isEmpty) {
    _showSnack('Veuillez remplir tous les champs.', isError: true);
    return;
  }

  setState(() => _isLoading = true);

  // Un seul appel — le backend détecte client ou coach
  final result = await ApiService.login(
    identifier: identifier,
    password: password,
  );

  if (!mounted) return;
  setState(() => _isLoading = false);

  if (result['success'] == true) {
    final role = result['role'];

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const HomeScreen(), // adapter selon le rôle si besoin
      ),
    );
  } else {
    _showSnack(result['message'] ?? 'Identifiants incorrects.', isError: true);
  }
}

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? const Color(0xFFFF4444) : kNeonGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Background image top ──
          Positioned(
            top: 0, left: 0, right: 0, height: 320,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset('assets/gym.jpeg', fit: BoxFit.cover),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x330A0A0A), Color(0xA60A0A0A), kDarkBg],
                      stops: [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Neon glow blobs ──
          Positioned(
            top: -80, right: -80,
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [kNeonGreen.withOpacity(0.10), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40, left: -50,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [kNeonGreen.withOpacity(0.06), Colors.transparent],
                ),
              ),
            ),
          ),

          // ── Main content ──
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 52),
                  _buildLogo(),
                  const SizedBox(height: 150),
                  _buildHeadline(),
                  const SizedBox(height: 4),
                  Text(
                    'Sign in to continue your journey',
                    style: TextStyle(color: kGrayText, fontSize: 13),
                  ),
                  const SizedBox(height: 28),

                  _buildInputLabel('USERNAME OR EMAIL'),
                  const SizedBox(height: 7),
                  _buildTextField(
                    controller: _identifierController,
                    hint: 'Enter your username or email',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 14),

                  _buildInputLabel('PASSWORD'),
                  const SizedBox(height: 7),
                  _buildTextField(
                    controller: _passwordController,
                    hint: 'Enter your password',
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                  ),
                  const SizedBox(height: 10),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                      ),
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: kNeonGreen, fontSize: 12, fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildConnexionButton(),
                  const SizedBox(height: 18),
                  _buildOrDivider(),
                  const SizedBox(height: 18),
                  _buildGoogleButton(),
                  const SizedBox(height: 20),
                  _buildSignUpRow(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: kNeonGreen.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kNeonGreen.withOpacity(0.35), width: 1),
            boxShadow: [BoxShadow(color: kNeonGreen.withOpacity(0.25), blurRadius: 20)],
          ),
          child: const Icon(Icons.fitness_center, color: kNeonGreen, size: 24),
        ),
        const SizedBox(height: 8),
        const Text(
          'GYMFUEL',
          style: TextStyle(
            color: kNeonGreen, fontSize: 22, fontWeight: FontWeight.w900,
            letterSpacing: 5,
            shadows: [Shadow(color: Color(0x66A3FF12), blurRadius: 16)],
          ),
        ),
      ],
    );
  }

  Widget _buildHeadline() {
    return RichText(
      text: const TextSpan(
        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 34, height: 1.05),
        children: [
          TextSpan(text: 'WELCOME\n', style: TextStyle(color: Colors.white)),
          TextSpan(text: 'BACK.', style: TextStyle(color: kNeonGreen)),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: kGrayText, fontSize: 11,
        fontWeight: FontWeight.w700, letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.10), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(icon, color: kGrayText, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: isPassword ? _obscurePassword : false,
              onSubmitted: (_) => isPassword ? _handleLogin() : null,
              style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: kGrayText.withOpacity(0.55), fontSize: 14),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (isPassword)
            GestureDetector(
              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
              child: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: kGrayText, size: 18,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConnexionButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleLogin,
      style: ElevatedButton.styleFrom(
        backgroundColor: kNeonGreen,
        disabledBackgroundColor: kNeonGreen.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 12,
        shadowColor: kNeonGreen.withOpacity(0.45),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(kDarkBg),
              ),
            )
          : const Text(
              'CONNEXION →',
              style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w900,
                letterSpacing: 2, color: kDarkBg,
              ),
            ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withOpacity(0.07), height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'OR',
            style: TextStyle(color: kGrayText, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
          ),
        ),
        Expanded(child: Divider(color: Colors.white.withOpacity(0.07), height: 1)),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return GestureDetector(
      onTap: () {}, // À implémenter avec google_sign_in
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.09), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20, height: 20,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              alignment: Alignment.center,
              child: const Text(
                'G',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF4285F4)),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Continue with Google',
              style: TextStyle(color: kLightGray, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Don't have an account?  ", style: TextStyle(color: kGrayText, fontSize: 13)),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          ),
          child: const Text(
            'Sign Up',
            style: TextStyle(color: kNeonGreen, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}