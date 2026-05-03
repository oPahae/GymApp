import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:test_hh/constants/colors.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/gym.jpeg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x4D0A0A0A), // 30%
                    Color(0x990A0A0A), // 60%
                    Color(0xF20A0A0A), // 95%
                    kDarkBg,
                  ],
                  stops: [0.0, 0.35, 0.60, 0.80],
                ),
              ),
            ),
          ),

          // ── Neon glow blob top-right ──
          Positioned(
            top: -60,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    kNeonGreen.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Main content ──
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                _buildLogo(),

                const Spacer(),

                // Bottom section
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeadline(),
                      const SizedBox(height: 12),
                      _buildSubtitle(),
                      const SizedBox(height: 24),
                      _buildFeaturePills(),
                      const SizedBox(height: 28),
                      const Divider(color: Colors.white10, height: 1),
                      const SizedBox(height: 24),
                      _buildGetStartedButton(context),
                      const SizedBox(height: 14),
                      _buildSignInRow(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: kNeonGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kNeonGreen.withOpacity(0.35), width: 1),
              boxShadow: [
                BoxShadow(
                  color: kNeonGreen.withOpacity(0.25),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: const Icon(Icons.fitness_center, color: kNeonGreen, size: 26),
          ),
          const SizedBox(height: 8),
          const Text(
            'GYMFUEL',
            style: TextStyle(
              color: kNeonGreen,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 5,
              shadows: [
                Shadow(color: Color(0x66A3FF12), blurRadius: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeadline() {
    return RichText(
      text: const TextSpan(
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 44,
          height: 1.05,
          letterSpacing: 0.5,
        ),
        children: [
          TextSpan(text: 'FUEL YOUR\n', style: TextStyle(color: Colors.white)),
          TextSpan(text: 'BEST SELF.', style: TextStyle(color: kNeonGreen)),
        ],
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'Track workouts, count calories, fuel your body,\nand achieve your fitness goals faster.',
      style: TextStyle(
        color: kGrayText,
        fontSize: 14,
        height: 1.6,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildFeaturePills() {
    const features = ['Calorie Tracking', 'Meal Planning', 'AI Coaching'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: features
          .map(
            (f) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kNeonGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: kNeonGreen.withOpacity(0.25), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: kNeonGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: kNeonGreen.withOpacity(0.8), blurRadius: 4),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    f,
                    style: const TextStyle(
                      color: kNeonGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildGetStartedButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: kNeonGreen,
          foregroundColor: kDarkBg,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 17),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: kNeonGreen.withOpacity(0.5),
        ).copyWith(
          elevation: WidgetStateProperty.all(12),
        ),
        child: const Text(
          'GET STARTED FREE →',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Color(0xFF0A0A0A),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account?  ',
          style: TextStyle(color: kGrayText, fontSize: 13),
        ),
        GestureDetector(
          onTap: () {},
          child: const Text(
            'Sign In',
            style: TextStyle(
              color: kNeonGreen,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}