import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/widgets/fluxa_logo.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey      = GlobalKey<FormState>();

  bool _isSignUp      = false;
  bool _obscurePass   = true;
  bool _emailExpanded = false;

  late AnimationController _ctrl;
  late Animation<double>   _fade;
  late Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth      = ref.watch(authProvider);
    final isLoading = auth.status == AuthStatus.loading;

    ref.listen<AuthState>(authProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!),
          backgroundColor: AppColors.error,
        ));
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _Background(),

          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const _LogoSection(),
                          const SizedBox(height: 48),

                          // Card principal
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: AppColors.divider, width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 40,
                                  offset: const Offset(0, 20),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                            child: Column(
                              children: [
                                Text(
                                  _isSignUp ? 'Criar conta' : 'Bem-vindo de volta',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                      fontSize: 26, fontWeight: FontWeight.w800,
                                      color: Colors.white, letterSpacing: -0.5),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _isSignUp
                                      ? 'Junte-se à economia circular.'
                                      : 'Acesse sua conta para continuar.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                      fontSize: 15, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 40),

                                // Formulário
                                _EmailForm(
                                  formKey:      _formKey,
                                  emailCtrl:    _emailCtrl,
                                  passwordCtrl: _passwordCtrl,
                                  obscurePass:  _obscurePass,
                                  isSignUp:     _isSignUp,
                                  isLoading:    isLoading,
                                  onTogglePass: () => setState(() => _obscurePass = !_obscurePass),
                                  onSubmit:     _submit,
                                ),

                                const SizedBox(height: 32),
                                GestureDetector(
                                  onTap: () => setState(() {
                                    _isSignUp = !_isSignUp;
                                    _emailExpanded = false;
                                  }),
                                  child: RichText(
                                    text: TextSpan(
                                      style: GoogleFonts.inter(
                                          fontSize: 14, color: AppColors.textSecondary),
                                      children: [
                                        TextSpan(
                                            text: _isSignUp ? 'Já tem conta? ' : 'Não tem conta? '),
                                        TextSpan(
                                          text: _isSignUp ? 'Entrar' : 'Criar conta grátis',
                                          style: GoogleFonts.inter(
                                              color: AppColors.success,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final n = ref.read(authProvider.notifier);
    if (_isSignUp) {
      n.signUpWithEmail(_emailCtrl.text.trim(), _passwordCtrl.text);
    } else {
      n.signInWithEmail(_emailCtrl.text.trim(), _passwordCtrl.text);
    }
  }
}

// ── Background ─────────────────────────────────────────────────────────────────
class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Stack(
        children: [
          Positioned(
            top: -150, left: 0, right: 0,
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.success.withOpacity(0.08),
                    AppColors.success.withOpacity(0),
                  ],
                  radius: 1.2,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -200, right: -100,
            child: Container(
              width: 500, height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.primary.withOpacity(0.05),
                  AppColors.primary.withOpacity(0),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Logo ───────────────────────────────────────────────────────────────────────
class _LogoSection extends StatelessWidget {
  const _LogoSection();

  @override
  Widget build(BuildContext context) {
    return const FluxaLogo(size: 90, showText: true, darkBackground: true);
  }
}

// ── Social Button ──────────────────────────────────────────────────────────────
class _SocialBtn extends StatelessWidget {
  final IconData assetIcon;
  final String label;
  final VoidCallback? onTap;
  const _SocialBtn({required this.assetIcon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.divider, width: 0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(assetIcon, size: 22, color: AppColors.textPrimary),
            const SizedBox(width: 10),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

// ── Ghost Button ───────────────────────────────────────────────────────────────
class _GhostBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _GhostBtn({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.divider, width: 0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ── Or Divider ─────────────────────────────────────────────────────────────────
class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.divider, thickness: 0.8)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('ou',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecondary)),
        ),
        const Expanded(child: Divider(color: AppColors.divider, thickness: 0.8)),
      ],
    );
  }
}

// ── Email Form ─────────────────────────────────────────────────────────────────
class _EmailForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl, passwordCtrl;
  final bool obscurePass, isSignUp, isLoading;
  final VoidCallback onTogglePass, onSubmit;

  const _EmailForm({
    required this.formKey, required this.emailCtrl, required this.passwordCtrl,
    required this.obscurePass, required this.isSignUp, required this.isLoading,
    required this.onTogglePass, required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          _InputField(
            controller: emailCtrl,
            label: 'Email',
            hint: 'seu@email.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v == null || !v.contains('@')) ? 'E-mail inválido' : null,
          ),
          const SizedBox(height: 16),
          _InputField(
            controller: passwordCtrl,
            label: 'Senha',
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscure: obscurePass,
            suffix: IconButton(
              icon: Icon(
                obscurePass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                size: 20, color: AppColors.textSecondary,
              ),
              onPressed: onTogglePass,
            ),
            validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: isLoading ? null : onSubmit,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: isLoading
                    ? const SizedBox(width: 24, height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isSignUp ? 'Criar conta' : 'Entrar',
                            style: GoogleFonts.inter(
                                fontSize: 16, fontWeight: FontWeight.w700,
                                color: const Color(0xFF0A0A0B)),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20, color: Color(0xFF0A0A0B)),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const _InputField({
    required this.controller, required this.label, required this.hint,
    required this.icon, this.obscure = false, this.keyboardType, this.suffix, this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller:   controller,
          obscureText:  obscure,
          keyboardType: keyboardType,
          validator:    validator,
          style: GoogleFonts.inter(fontSize: 15, color: Colors.white),
          decoration: InputDecoration(
            hintText:   hint,
            hintStyle:  GoogleFonts.inter(color: AppColors.textTertiary),
            prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
            suffixIcon: suffix,
            filled:     true,
            fillColor:  const Color(0xFF141416),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF27272A))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF27272A))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.success, width: 1.5)),
          ),
        ),
      ],
    );
  }
}
