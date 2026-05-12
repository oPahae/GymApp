import 'package:flutter/material.dart';
import 'package:test_hh/constants/names.dart';
import 'package:test_hh/screens/home.dart';

const kBg       = Color(0xFF080D08);
const kSurface  = Color(0xFF0F180F);
const kCard     = Color(0xFF131C13);
const kCardAlt  = Color(0xFF101810);
const kGreen    = Color(0xFF82D633);
const kGreenLt  = Color(0xFFAAF050);
const kGreenDim = Color(0xFF192B0F);
const kAccent   = Color(0xFFFFD93D);
const kRed      = Color(0xFFFF5252);
const kBlue     = Color(0xFF4FC3F7);
const kText     = Colors.white;
const kSub      = Color(0xFF8BA67A);
const kBorder   = Color(0xFF1C2B1C);

const _imgHero = 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&q=85';


void _goHome(BuildContext context) {
  Navigator.of(context).push(
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, a, __) => const HomeScreen(),
      transitionsBuilder: (_, a, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ),
  );
}

// ─── Splash ──────────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _scale = Tween(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _ctrl.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (_, a, __) => const WelcomeScreen(),
            transitionsBuilder: (_, a, __, child) =>
                FadeTransition(opacity: a, child: child),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Opacity(
            opacity: _fade.value,
            child: Transform.scale(
              scale: _scale.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [kGreen, kGreenLt],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: kGreen.withOpacity(0.4),
                          blurRadius: 40,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: const Icon(Icons.bolt_rounded,
                        color: Colors.black, size: 52),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    gymName,
                    style: TextStyle(
                      color: kText,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Fuel your performance',
                    style: TextStyle(
                        color: kSub, fontSize: 13, letterSpacing: 1.2),
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

// ─── Welcome ─────────────────────────────────────────────────────────────────

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slideUp;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _slideUp = Tween(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Hero background
          Positioned.fill(
            child: Image.network(
              _imgHero,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, prog) =>
                  prog == null ? child : const SizedBox.shrink(),
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFF0D1A0D)),
            ),
          ),

          // Gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.35, 0.65, 1.0],
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.82),
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),

          // Green ambient glow
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kGreen.withOpacity(0.12),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: kGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.bolt_rounded,
                            color: Colors.black, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        gymName,
                        style: TextStyle(
                          color: kText,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Animated bottom content
                SlideTransition(
                  position: _slideUp,
                  child: FadeTransition(
                    opacity: _fade,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: kGreenDim,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: kGreen.withOpacity(0.35)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.verified_rounded,
                                    color: kGreen, size: 14),
                                SizedBox(width: 6),
                                Text(
                                  'AI-Powered Nutrition Tracker',
                                  style: TextStyle(
                                      color: kGreen,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Headline
                          const Text(
                            'Fuel Your Body.\nCrush Every\nGoal.',
                            style: TextStyle(
                              color: kText,
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              height: 1.08,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Subtext
                          Text(
                            'Track calories, plan meals, and optimize your\nnutrition with smart AI insights.',
                            style: TextStyle(
                              color: kSub,
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Feature pills
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: const [
                              _FeaturePill(
                                  icon: Icons.track_changes_rounded,
                                  label: 'Calorie Tracking'),
                              _FeaturePill(
                                  icon: Icons.restaurant_menu_rounded,
                                  label: 'Meal Planning'),
                              _FeaturePill(
                                  icon: Icons.insights_rounded,
                                  label: 'Smart Insights'),
                            ],
                          ),
                          const SizedBox(height: 36),

                          // ── CTA button → HomeScreen ──
                          SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: ElevatedButton(
                              onPressed: () => _goHome(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kGreen,
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Get Started Free',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 20),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // ── Sign In → HomeScreen ──
                          Center(
                            child: GestureDetector(
                              onTap: () => _goHome(context),
                              child: RichText(
                                text: const TextSpan(
                                  style: TextStyle(color: kSub, fontSize: 13),
                                  children: [
                                    TextSpan(text: 'Already have an account? '),
                                    TextSpan(
                                      text: 'Sign In',
                                      style: TextStyle(
                                        color: kGreen,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Feature pill ─────────────────────────────────────────────────────────────

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: kGreen, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: kText, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}