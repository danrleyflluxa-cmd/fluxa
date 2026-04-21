import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/marketplace/presentation/pages/marketplace_page.dart';
import '../../features/wallet/presentation/pages/wallet_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/bottom_nav.dart';
import '../../shared/widgets/fluxa_logo.dart';
import '../../core/theme/app_theme.dart';

// ── Auth Guard ─────────────────────────────────────────────────────────────────
class AuthGuard extends ConsumerWidget {
  const AuthGuard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return switch (auth.status) {
      AuthStatus.loading          => const SplashScreen(),
      AuthStatus.unauthenticated  => const LoginPage(),
      AuthStatus.needsOnboarding  => const OnboardingPage(),
      AuthStatus.authenticated    => const AppShell(),
    };
  }
}

// ── App Shell com Bottom Nav ───────────────────────────────────────────────────
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final _pages = const [
    HomePage(),
    MarketplacePage(),
    WalletPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: FluxaBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ── Splash Screen ──────────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gradientStart,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A84FF), Color(0xFF0040CC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FluxaLogo(size: 100, showText: false, darkBackground: true),
                  const SizedBox(height: 24),
                  Text('Fluxa',
                      style: GoogleFonts.inter(
                          fontSize: 40, fontWeight: FontWeight.w800,
                          color: Colors.white, letterSpacing: -1.5)),
                  const SizedBox(height: 8),
                  Text('Economia circular inteligente',
                      style: GoogleFonts.inter(
                          fontSize: 16, color: Colors.white.withOpacity(0.75),
                          fontWeight: FontWeight.w400, letterSpacing: -0.2)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
