import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Palette ──
  static const _bgTop = Color(0xFF0D1F22); // Deep dark teal
  static const _bgBottom = Color(0xFF0A1A1E); // Near-black green
  static const _headline = Color(0xFFF4F0EA); // Warm cream white
  static const _subtext = Color(0xFFA3B0AC); // Muted sage
  static const _primaryBtn = Color(0xFFF4F0EA); // Light cream button
  static const _primaryBtnText = Color(0xFF0D1F22); // Dark text on light btn
  static const _secondaryBtn = Color(0xFF1C3338); // Deep glassy teal
  static const _secondaryBtnText = Color(0xFFCDD8D4); // Soft sage text
  static const _secondaryBtnBorder = Color(0xFF2D4A4E); // Subtle border
  static const _gold = Color(0xFFD4B896); // Champagne gold accent
  static const _linkText = Color(0xFF7A9A94); // Muted teal link

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _bgTop,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideUp,
            child: Column(
              children: [
                // ── Hero Art Area ──
                Expanded(
                  flex: 5,
                  child: Stack(
                    children: [
                      // Background atmospheric glow
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: const Alignment(0, -0.2),
                              radius: 0.9,
                              colors: [
                                const Color(0xFF1A3A3A).withValues(alpha: 0.6),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Hero image
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 60, left: 40, right: 40),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Image.asset(
                              'assets/images/welcome_hero.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      // Subtle bottom fade to merge into CTA area
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 80,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                _bgBottom.withValues(alpha: 0.95),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── CTA Area ──
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(28, 0, 28, bottomPad + 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Brand wordmark
                        const Text(
                          'leko',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: _headline,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Headline
                        Text(
                          'Where budgeting\nstarts to feel alive.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: _subtext,
                            height: 1.4,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Primary CTA — Continue with Apple
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            onPressed: () => context.go('/welcome/signup'),
                            style: FilledButton.styleFrom(
                              backgroundColor: _primaryBtn,
                              foregroundColor: _primaryBtnText,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.apple, size: 22, color: _primaryBtnText),
                                const SizedBox(width: 10),
                                const Text(
                                  'Continue with Apple',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Secondary CTA — Continue with Email
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton(
                            onPressed: () => context.go('/welcome/signup'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _secondaryBtn.withValues(alpha: 0.5),
                              foregroundColor: _secondaryBtnText,
                              side: BorderSide(
                                color: _secondaryBtnBorder.withValues(alpha: 0.6),
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Continue with email',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Tertiary — Already have an account?
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account?  ',
                              style: TextStyle(
                                color: _linkText,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.go('/welcome/login'),
                              child: const Text(
                                'Log in',
                                style: TextStyle(
                                  color: _gold,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                  decorationColor: _gold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
