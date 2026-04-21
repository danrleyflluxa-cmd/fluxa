import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../../shared/widgets/fluxa_logo.dart';

// ── Modelo de tipo de usuário ──────────────────────────────────────────────────
class _UserTypeOption {
  final String value;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> perks;

  const _UserTypeOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.perks,
  });
}

const _options = [
  _UserTypeOption(
    value:    'comprador',
    title:    'Comprador',
    subtitle: 'Compre com segurança e proteção total.',
    icon:     Icons.shopping_bag_rounded,
    color:    Color(0xFF007AFF),
    perks:    ['Pagamento protegido por escrow', 'Histórico de compras', 'Avaliação de vendedores'],
  ),
  _UserTypeOption(
    value:    'vendedor',
    title:    'Vendedor',
    subtitle: 'Venda seus produtos para toda a rede.',
    icon:     Icons.storefront_rounded,
    color:    Color(0xFF34C759),
    perks:    ['Dashboard de vendas', 'Recebimento garantido', 'Gestão de estoque'],
  ),
  _UserTypeOption(
    value:    'indicador',
    title:    'Indicador',
    subtitle: 'Indique e ganhe comissões automáticas.',
    icon:     Icons.share_rounded,
    color:    Color(0xFFAF52DE),
    perks:    ['Link de indicação único', 'Comissões em GiroCoin', 'Painel de performance'],
  ),
  _UserTypeOption(
    value:    'investidor',
    title:    'Investidor',
    subtitle: 'Invista na liquidez circular do ecossistema.',
    icon:     Icons.trending_up_rounded,
    color:    Color(0xFFFF9F0A),
    perks:    ['Rendimento em GiroCoin', 'Relatórios de liquidez', 'Acesso antecipado'],
  ),
];

// ── Page ───────────────────────────────────────────────────────────────────────
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage>
    with TickerProviderStateMixin {
  String? _selected;
  bool    _saving = false;

  late final List<AnimationController> _cardCtrls;
  late final List<Animation<double>>   _cardAnims;

  @override
  void initState() {
    super.initState();
    _cardCtrls = List.generate(_options.length, (i) =>
        AnimationController(vsync: this, duration: const Duration(milliseconds: 400)));
    _cardAnims = _cardCtrls.map((c) =>
        CurvedAnimation(parent: c, curve: Curves.easeOutCubic)).toList();

    // Stagger de entrada
    for (var i = 0; i < _cardCtrls.length; i++) {
      Future.delayed(Duration(milliseconds: 100 + i * 80), () {
        if (mounted) _cardCtrls[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _cardCtrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FluxaLogo(size: 44, showText: false, darkBackground: false),
                  const SizedBox(height: 20),
                  Text('Como você vai\nusar o Fluxa?',
                      style: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary, height: 1.2, letterSpacing: -0.8)),
                  const SizedBox(height: 8),
                  Text('Escolha seu perfil principal. Você pode expandir depois.',
                      style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSecondary)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Cards ─────────────────────────────────────────────────────────
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _options.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final opt = _options[i];
                  return SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
                        .animate(_cardAnims[i]),
                    child: FadeTransition(
                      opacity: _cardAnims[i],
                      child: _ProfileCard(
                        option:     opt,
                        isSelected: _selected == opt.value,
                        onTap:      () {
                          HapticFeedback.selectionClick();
                          setState(() => _selected = opt.value);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Botão de confirmação ──────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
              child: AnimatedOpacity(
                opacity: _selected != null ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 200),
                child: ElevatedButton(
                  onPressed: (_selected != null && !_saving) ? _confirm : null,
                  child: _saving
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Text('Começar agora'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    if (_selected == null) return;
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    try {
      final client = ref.read(supabaseClientProvider);
      final user   = client.auth.currentUser!;

      // Upsert do perfil com o user_type escolhido
      await client.from('profiles').upsert({
        'id':        user.id,
        'email':     user.email ?? '',
        'full_name': user.userMetadata?['full_name'] ?? user.email?.split('@').first ?? 'Usuário',
        'user_type': _selected,
      });

      // Wallet é criada pelo trigger, mas garante caso não exista
      await client.from('wallets').upsert({
        'user_id': user.id,
      }, onConflict: 'user_id');

      HapticFeedback.heavyImpact();

      // Força re-check do perfil → AuthGuard redireciona para AppShell
      await ref.read(authProvider.notifier).refreshProfile();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao salvar perfil: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Profile Card ───────────────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final _UserTypeOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProfileCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? option.color.withOpacity(0.06) : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? option.color : AppColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: option.color.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 4))]
              : [],
        ),
        child: Row(
          children: [
            // Ícone
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: option.color.withOpacity(isSelected ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(option.icon, color: option.color, size: 26),
            ),
            const SizedBox(width: 14),

            // Texto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(option.title,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                          color: isSelected ? option.color : AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text(option.subtitle,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.3)),
                  if (isSelected) ...[
                    const SizedBox(height: 10),
                    ...option.perks.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        children: [
                          Icon(Icons.check_rounded, size: 13, color: option.color),
                          const SizedBox(width: 5),
                          Text(p, style: TextStyle(fontSize: 12, color: option.color,
                              fontWeight: FontWeight.w500)),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ),

            // Indicador de seleção
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? option.color : Colors.transparent,
                border: Border.all(
                  color: isSelected ? option.color : AppColors.divider,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
