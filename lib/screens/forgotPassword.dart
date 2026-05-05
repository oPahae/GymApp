import 'package:flutter/material.dart';
import 'package:test_hh/constants/colors.dart';
import 'package:test_hh/screens/login.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showSnack('Veuillez entrer votre email.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Appel à votre API pour envoyer l'email de réinitialisation
      // Exemple: await ApiService.forgotPassword(email: email);
      await Future.delayed(const Duration(seconds: 2)); // Simuler un appel API

      if (!mounted) return;

      _showSnack(
        'Un email de réinitialisation a été envoyé à $email.',
        isError: false,
      );
    } catch (e) {
      _showSnack('Erreur lors de l\'envoi de l\'email.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
            top: 0,
            left: 0,
            right: 0,
            height: 320,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset('assets/gym.jpeg', fit: BoxFit.cover),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x330A0A0A),
                        Color(0xA60A0A0A),
                        kDarkBg
                      ],
                      stops: [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Neon glow blobs ──
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    kNeonGreen.withOpacity(0.10),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    kNeonGreen.withOpacity(0.06),
                    Colors.transparent
                  ],
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
                    'Enter your email to reset your password',
                    style: TextStyle(color: kGrayText, fontSize: 13),
                  ),
                  const SizedBox(height: 28),

                  _buildInputLabel('EMAIL'),
                  const SizedBox(height: 7),
                  _buildTextField(
                    controller: _emailController,
                    hint: 'Enter your email',
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 24),

                  _buildResetButton(),
                  const SizedBox(height: 20),

                  // Retour à la page de connexion
                  Align(
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Remember your password? ',
                              style: TextStyle(color: kGrayText, fontSize: 13),
                            ),
                            const TextSpan(
                              text: 'Sign In',
                              style: TextStyle(
                                color: kNeonGreen,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: kNeonGreen.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: kNeonGreen.withOpacity(0.35),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: kNeonGreen.withOpacity(0.25),
                blurRadius: 20,
              )
            ],
          ),
          child: const Icon(
            Icons.fitness_center,
            color: kNeonGreen,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'GYMFUEL',
          style: TextStyle(
            color: kNeonGreen,
            fontSize: 22,
            fontWeight: FontWeight.w900,
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
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 34,
          height: 1.05,
        ),
        children: [
          TextSpan(text: 'RESET\n', style: TextStyle(color: Colors.white)),
          TextSpan(text: 'PASSWORD.', style: TextStyle(color: kNeonGreen)),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: kGrayText,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.10),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(icon, color: kGrayText, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: kGrayText.withOpacity(0.55),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleForgotPassword,
      style: ElevatedButton.styleFrom(
        backgroundColor: kNeonGreen,
        disabledBackgroundColor: kNeonGreen.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
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
              'SEND RESET LINK →',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: kDarkBg,
              ),
            ),
    );
  }
}