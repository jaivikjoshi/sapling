import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/leko_mark.dart';

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
        color: _bgTop,
        child: FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideUp,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isShort = constraints.maxHeight < 720;
                  final heroHeight = (constraints.maxHeight * 0.44).clamp(
                    210.0,
                    360.0,
                  );
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(28, 8, 28, bottomPad + 18),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - bottomPad - 26,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            height: isShort ? 190 : heroHeight,
                            child: Center(
                              child: Container(
                                width: isShort ? 150 : 178,
                                height: isShort ? 150 : 178,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(42),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.09),
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x26000000),
                                      blurRadius: 30,
                                      offset: Offset(0, 16),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: LekoMark(
                                    size: 98,
                                    color: Color(0xFFB4B6B7),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: isShort ? 12 : 20),
                            child: Column(
                              children: [
                                const Text(
                                  'leko',
                                  style: TextStyle(
                                    fontFamily: 'Georgia',
                                    fontSize: 36,
                                    fontWeight: FontWeight.w700,
                                    color: _headline,
                                    letterSpacing: 0,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'Where budgeting\nstarts to feel alive.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w400,
                                    color: _subtext,
                                    height: 1.4,
                                    letterSpacing: 0,
                                  ),
                                ),
                                SizedBox(height: isShort ? 22 : 36),
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: FilledButton(
                                    onPressed:
                                        () => context.go('/welcome/signup'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _primaryBtn,
                                      foregroundColor: _primaryBtnText,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.apple,
                                          size: 22,
                                          color: _primaryBtnText,
                                        ),
                                        const SizedBox(width: 10),
                                        const Flexible(
                                          child: Text(
                                            'Continue with Apple',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: OutlinedButton(
                                    onPressed:
                                        () => context.go('/welcome/signup'),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: _secondaryBtn.withValues(
                                        alpha: 0.5,
                                      ),
                                      foregroundColor: _secondaryBtnText,
                                      side: BorderSide(
                                        color: _secondaryBtnBorder.withValues(
                                          alpha: 0.6,
                                        ),
                                        width: 1,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      'Continue with email',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    const Text(
                                      'Already have an account? ',
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
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
