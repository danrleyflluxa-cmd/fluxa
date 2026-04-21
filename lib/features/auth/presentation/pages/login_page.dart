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
          // Fundo com orbs decorativos
          const _Background(),

          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 56),
                      const _LogoSection(),
                      const SizedBox(height: 40),

                      // Card principal
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          boxShadow: AppShadows.elevated,
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isSignUp ? 'Criar conta' : 'Bem-vindo de volta',
                              style: GoogleFonts.inter(
                                  fontSize: 22, fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary, letterSpacing: -0.4),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isSignUp
                                  ? 'Junte-se à economia circular.'
                                  : 'Entre para continuar no Fluxa.',
                              style: GoogleFonts.inter(
                                  fontSize: 15, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 24),

                            // Social
                            _SocialBtn(
                              assetIcon: Icons.g_mobiledata_rounded,
                              label: 'Continuar com Google',
                              onTap: isLoading ? null
                                  : () => ref.read(authProvider.notifier).signInWithGoogle(),
                            ),
                            const SizedBox(height: 10),
                            _SocialBtn(
                              assetIcon: Icons.apple_rounded,
                              label: 'Continuar com Apple',
                              onTap: isLoading ? null
                                  : () => ref.read(authProvider.notifier).signInWithApple(),
                            ),

                            const SizedBox(height: 20),
                            _OrDivider(),
                            const SizedBox(height: 20),

                            // E-mail progressivo
                            AnimatedSize(
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeOutCubic,
                              child: !_emailExpanded
                                  ? _GhostBtn(
                                      label: 'Continuar com e-mail',
                                      icon: Icons.mail_outline_rounded,
                                      onTap: () => setState(() => _emailExpanded = true),
                                    )
                                  : _EmailForm(
                                      formKey:      _formKey,
                                      emailCtrl:    _emailCtrl,
                                      passwordCtrl: _passwordCtrl,
                                      obscurePass:  _obscurePass,
                                      isSignUp:     _isSignUp,
                                      isLoading:    isLoading,
                                      onTogglePass: () => setState(() => _obscurePass = !_obscurePass),
                                      onSubmit:     _submit,
                                    ),
                            ),

                            const SizedBox(height: 20),
                            Center(
                              child: GestureDetector(
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
                                        text: _isSignUp ? 'Entrar' : 'Criar agora',
                                        style: GoogleFonts.inter(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),
                      Text(
                        'Ao continuar, você concorda com os\nTermos de Uso e Política de Privacidade.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary.withOpacity(0.6),
                            height: 1.6),
                      ),
                      const SizedBox(height: 32),
                    ],
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
            top: -120, right: -80,
            child: Container(
              width: 320, height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.primary.withOpacity(0.12),
                  AppColors.primary.withOpacity(0),
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -140, left: -100,
            child: Container(
              width: 360, height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.primaryDark.withOpacity(0.08),
                  AppColors.primaryDark.withOpacity(0),
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
    return const FluxaLogo(size: 80, showText: true, darkBackground: false);
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
            label: 'E-mail',
            hint: 'seu@email.com',
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v == null || !v.contains('@')) ? 'E-mail inválido' : null,
          ),
          const SizedBox(height: 12),
          _InputField(
            controller: passwordCtrl,
            label: 'Senha',
            hint: '••••••••',
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
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: isLoading ? null : onSubmit,
            child: isLoading
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : Text(isSignUp ? 'Criar conta' : 'Entrar'),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const _InputField({
    required this.controller, required this.label, required this.hint,
    this.obscure = false, this.keyboardType, this.suffix, this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:   controller,
      obscureText:  obscure,
      keyboardType: keyboardType,
      validator:    validator,
      style: GoogleFonts.inter(fontSize: 15, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText:  label,
        hintText:   hint,
        suffixIcon: suffix,
        filled:     true,
        fillColor:  AppColors.background,
      ),
    );
  }
}
