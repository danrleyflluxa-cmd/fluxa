import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/profile_provider.dart';
import '../../../../shared/providers/transactions_provider.dart';
import '../../../wallet/domain/transaction_model.dart';
import 'edit_profile_page.dart';
import 'settings_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final txAsync      = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:   (_, __) => const Center(child: Text('Erro ao carregar perfil')),
          data: (profile) {
            if (profile == null) return const SizedBox.shrink();

            final totalTx = txAsync.valueOrNull?.length ?? 0;
            final sales   = txAsync.valueOrNull
                ?.where((t) => t.sellerId == profile.id && t.status.isReleased)
                .length ?? 0;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // ── Header ─────────────────────────────────────────────
                      _ProfileHeader(profile: profile),
                      const SizedBox(height: 24),

                      // ── Score Fluxa ────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _ScoreCard(score: profile.scoreReputation),
                      ),
                      const SizedBox(height: 16),

                      // ── Stats ──────────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _StatsRow(
                          sales:      sales,
                          totalTx:    totalTx,
                          memberDays: profile.membershipDays,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Menu ───────────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const _MenuSection(),
                      ),
                      const SizedBox(height: 24),

                      // ── Logout ─────────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                        child: _LogoutButton(
                          onTap: () => ref.read(authProvider.notifier).signOut(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Profile Header ─────────────────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final ProfileData profile;
  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 84, height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF007AFF), Color(0xFF0055CC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withOpacity(0.25),
                        blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: profile.avatarUrl != null
                    ? ClipOval(child: Image.network(profile.avatarUrl!, fit: BoxFit.cover))
                    : Center(
                        child: Text(
                          profile.fullName.isNotEmpty
                              ? profile.fullName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: const Icon(CupertinoIcons.pencil, size: 13, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(profile.fullName,
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(profile.userTypeLabel,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
          ),
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(profile.bio!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4)),
          ],
        ],
      ),
    );
  }
}

// ── Score Card ─────────────────────────────────────────────────────────────────
class _ScoreCard extends StatelessWidget {
  final double score; // 0–100
  const _ScoreCard({required this.score});

  Color get _scoreColor {
    if (score >= 80) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }

  String get _scoreLabel {
    if (score >= 80) return 'Excelente';
    if (score >= 50) return 'Bom';
    if (score >= 20) return 'Regular';
    return 'Iniciante';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          // Medidor circular
          SizedBox(
            width: 72, height: 72,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 6,
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation(_scoreColor),
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Text(
                    score.toInt().toString(),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                        color: _scoreColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Score Fluxa',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(_scoreLabel,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                        color: _scoreColor)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    minHeight: 5,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation(_scoreColor),
                  ),
                ),
                const SizedBox(height: 5),
                const Text('Complete transações para aumentar seu score.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats Row ──────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final int sales, totalTx, memberDays;
  const _StatsRow({required this.sales, required this.totalTx, required this.memberDays});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          icon:  CupertinoIcons.bag_badge_plus,
          value: sales.toString(),
          label: 'Vendas',
          color: AppColors.success,
        ),
        const SizedBox(width: 10),
        _StatCard(
          icon:  CupertinoIcons.arrow_2_circlepath,
          value: totalTx.toString(),
          label: 'Transações',
          color: AppColors.primary,
        ),
        const SizedBox(width: 10),
        _StatCard(
          icon:  CupertinoIcons.calendar,
          value: memberDays < 30 ? '${memberDays}d' : '${(memberDays / 30).floor()}m',
          label: 'Na plataforma',
          color: AppColors.warning,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;

  const _StatCard({
    required this.icon, required this.value,
    required this.label, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ── Menu Section ───────────────────────────────────────────────────────────────
class _MenuSection extends StatelessWidget {
  const _MenuSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _MenuItem(icon: CupertinoIcons.person,          label: 'Editar perfil',
              onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const EditProfilePage()))),
          _Divider(),
          _MenuItem(icon: CupertinoIcons.bell,            label: 'Notificações',
              onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const NotificationsPage()))),
          _Divider(),
          _MenuItem(icon: CupertinoIcons.shield,          label: 'Segurança',
              onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const SecurityPage()))),
          _Divider(),
          _MenuItem(icon: CupertinoIcons.question_circle, label: 'Ajuda e suporte',
              onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const HelpPage()))),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(child: Text(label,
                style: const TextStyle(fontSize: 15, color: AppColors.textPrimary))),
            const Icon(CupertinoIcons.chevron_right, size: 16, color: AppColors.divider),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 50, endIndent: 16, color: AppColors.divider);
}

// ── Logout Button ──────────────────────────────────────────────────────────────
class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('Sair da conta'),
          content: const Text('Tem certeza que deseja sair?'),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () { Navigator.pop(context); onTap(); },
              child: const Text('Sair'),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.error.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(CupertinoIcons.square_arrow_left, size: 18, color: AppColors.error),
            SizedBox(width: 8),
            Text('Sair da conta',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.error)),
          ],
        ),
      ),
    );
  }
}
