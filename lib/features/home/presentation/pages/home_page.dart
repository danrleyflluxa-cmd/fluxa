import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/providers/profile_provider.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/providers/transactions_provider.dart';
import '../../../../features/wallet/domain/transaction_model.dart';
import '../../../../features/wallet/presentation/widgets/deposit_sheet.dart';
import '../../../../features/wallet/presentation/widgets/transfer_sheet.dart';
import '../../../../shared/widgets/fluxa_logo.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile    = ref.watch(profileProvider).valueOrNull;
    final wallet     = ref.watch(walletProvider).valueOrNull;
    final txs        = ref.watch(transactionsProvider).valueOrNull ?? [];
    final userName   = profile?.fullName.split(' ').first ?? '...';
    final userType   = profile?.userType ?? 'comprador';
    final balanceBrl = wallet?.balanceBrl ?? 0.0;
    final girocoins  = wallet?.balanceGirocoin ?? 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Olá, $userName 👋',
                              style: GoogleFonts.inter(
                                  fontSize: 24, fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary, letterSpacing: -0.5)),
                          const SizedBox(height: 2),
                          Text(_userTypeLabel(userType),
                              style: GoogleFonts.inter(
                                  fontSize: 14, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: AppColors.primary, size: 22),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 20),
                  _WalletCard(balanceBrl: balanceBrl, girocoins: girocoins),
                  const SizedBox(height: 24),
                  if (userType == 'vendedor') const _SellerQuickActions(),
                  if (userType != 'vendedor') const _BuyerQuickActions(),
                  const SizedBox(height: 28),
                  _SectionHeader(title: 'Atividade Recente'),
                  const SizedBox(height: 12),
                  _ActivityTimeline(transactions: txs),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _userTypeLabel(String type) => const {
    'vendedor':   'Conta Vendedor',
    'comprador':  'Conta Comprador',
    'indicador':  'Conta Indicador',
    'investidor': 'Conta Investidor',
  }[type] ?? 'Fluxa';
}

// ── Wallet Card ────────────────────────────────────────────────────────────────
class _WalletCard extends StatelessWidget {
  final double balanceBrl, girocoins;
  const _WalletCard({required this.balanceBrl, required this.girocoins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.primaryGlow(AppColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Saldo disponível',
              style: GoogleFonts.inter(
                  fontSize: 13, color: Colors.white.withOpacity(0.75),
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(
            'R\$ ${balanceBrl.toStringAsFixed(2).replaceAll('.', ',')}',
            style: GoogleFonts.inter(
                fontSize: 34, fontWeight: FontWeight.w800,
                color: Colors.white, letterSpacing: -1.0),
          ),
          const SizedBox(height: 16),
          Container(height: 0.5, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.toll_rounded, color: Colors.white60, size: 15),
              const SizedBox(width: 6),
              Text('${girocoins.toStringAsFixed(0)} GiroCoins',
                  style: GoogleFonts.inter(
                      fontSize: 14, color: Colors.white.withOpacity(0.75))),
              const Spacer(),
              _WalletAction(
                label: 'Depositar',
                icon: Icons.add_rounded,
                onTap: () => showModalBottomSheet(
                  context: context, isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const DepositSheet(),
                ),
              ),
              const SizedBox(width: 8),
              _WalletAction(
                label: 'Transferir',
                icon: Icons.arrow_forward_rounded,
                onTap: () => showModalBottomSheet(
                  context: context, isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const TransferSheet(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WalletAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _WalletAction({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 5),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── Quick Actions ──────────────────────────────────────────────────────────────
class _SellerQuickActions extends StatelessWidget {
  const _SellerQuickActions();
  @override
  Widget build(BuildContext context) => _ActionsRow(actions: const [
    _Action(icon: Icons.add_box_rounded,      label: 'Produto',    color: AppColors.success),
    _Action(icon: Icons.receipt_long_rounded, label: 'Pedidos',    color: AppColors.warning),
    _Action(icon: Icons.bar_chart_rounded,    label: 'Relatórios', color: AppColors.primary),
    _Action(icon: Icons.campaign_rounded,     label: 'Promover',   color: AppColors.purple),
  ]);
}

class _BuyerQuickActions extends StatelessWidget {
  const _BuyerQuickActions();
  @override
  Widget build(BuildContext context) => _ActionsRow(actions: const [
    _Action(icon: Icons.search_rounded,         label: 'Explorar',  color: AppColors.primary),
    _Action(icon: Icons.favorite_rounded,       label: 'Favoritos', color: AppColors.error),
    _Action(icon: Icons.local_shipping_rounded, label: 'Pedidos',   color: AppColors.warning),
    _Action(icon: Icons.redeem_rounded,         label: 'Indicar',   color: AppColors.success),
  ]);
}

class _Action {
  final IconData icon;
  final String label;
  final Color color;
  const _Action({required this.icon, required this.label, required this.color});
}

class _ActionsRow extends StatelessWidget {
  final List<_Action> actions;
  const _ActionsRow({required this.actions});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((a) => _ActionBtn(action: a)).toList(),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final _Action action;
  const _ActionBtn({required this.action});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 62, height: 62,
          decoration: BoxDecoration(
            color: action.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: action.color.withOpacity(0.15)),
          ),
          child: Icon(action.icon, color: action.color, size: 26),
        ),
        const SizedBox(height: 7),
        Text(action.label,
            style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w500,
                color: AppColors.textSecondary)),
      ],
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w700,
            color: AppColors.textPrimary, letterSpacing: -0.3));
  }
}

// ── Activity Timeline ──────────────────────────────────────────────────────────
class _ActivityTimeline extends StatelessWidget {
  final List<TransactionModel> transactions;
  const _ActivityTimeline({required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          children: [
            Icon(Icons.receipt_long_rounded, size: 36,
                color: AppColors.textSecondary.withOpacity(0.3)),
            const SizedBox(height: 10),
            Text('Nenhuma atividade ainda',
                style: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    final recent = transactions.take(5).toList();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: List.generate(recent.length, (i) {
          final tx         = recent[i];
          final isLast     = i == recent.length - 1;
          final isPaid     = tx.status == TransactionStatus.paid;
          final isReleased = tx.status == TransactionStatus.released;
          final color      = isReleased ? AppColors.success
                           : isPaid    ? AppColors.warning
                           : AppColors.error;
          final icon       = isReleased ? Icons.arrow_downward_rounded
                           : isPaid    ? Icons.lock_rounded
                           : Icons.arrow_upward_rounded;
          final label      = isReleased ? 'Pagamento recebido'
                           : isPaid    ? 'Valor em custódia'
                           : 'Compra realizada';
          final dt         = tx.createdAt;
          final timeStr    = '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')} '
                             '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label,
                              style: GoogleFonts.inter(
                                  fontSize: 14, fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                          Text(tx.trackingCode ?? '—',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('R\$ ${tx.amount.toStringAsFixed(2).replaceAll('.', ',')}',
                            style: GoogleFonts.inter(
                                fontSize: 14, fontWeight: FontWeight.w700, color: color)),
                        Text(timeStr,
                            style: GoogleFonts.inter(
                                fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(height: 1, indent: 68, endIndent: 16),
            ],
          );
        }),
      ),
    );
  }
}
