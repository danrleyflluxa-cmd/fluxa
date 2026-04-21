import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/wallet/domain/transaction_model.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/providers/transactions_provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../widgets/deposit_sheet.dart';
import '../widgets/transfer_sheet.dart';

class WalletPage extends ConsumerWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);
    final txAsync     = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text('Carteira',
                    style: Theme.of(context).textTheme.displayLarge),
              ),
            ),

            // ── Cards de Saldo ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: walletAsync.when(
                  loading: () => const _BalanceCardSkeleton(),
                  error:   (_, __) => const _ErrorCard(),
                  data:    (wallet) => wallet == null
                      ? const _ErrorCard()
                      : _BalanceSection(
                          balanceBrl:    wallet.balanceBrl,
                          frozenBalance: wallet.frozenBalance,
                          girocoins:     wallet.balanceGirocoin,
                        ),
                ),
              ),
            ),

            // ── Transações em Escrow Ativas ──────────────────────────────────
            txAsync.when(
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error:   (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              data: (txs) {
                final active = txs.where((t) => t.status.isEscrowActive).toList();
                if (active.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionLabel('Em andamento'),
                        const SizedBox(height: 10),
                        ...active.map((tx) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _EscrowActiveCard(transaction: tx),
                        )),
                      ],
                    ),
                  ),
                );
              },
            ),

            // ── Histórico ────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              sliver: txAsync.when(
                loading: () => const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator())),
                error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                data: (txs) {
                  final history = txs.where((t) => !t.status.isEscrowActive).toList();
                  return SliverList(
                    delegate: SliverChildListDelegate([
                      const _SectionLabel('Histórico'),
                      const SizedBox(height: 10),
                      if (history.isEmpty)
                        const _EmptyHistory()
                      else
                        _TransactionList(transactions: history),
                    ]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Seção de Saldo ─────────────────────────────────────────────────────────────
class _BalanceSection extends StatelessWidget {
  final double balanceBrl, frozenBalance, girocoins;
  const _BalanceSection({
    required this.balanceBrl,
    required this.frozenBalance,
    required this.girocoins,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MainBalanceCard(balanceBrl: balanceBrl, girocoins: girocoins),
        if (frozenBalance > 0) ...[
          const SizedBox(height: 12),
          _FrozenBalanceCard(frozenBalance: frozenBalance),
        ],
      ],
    );
  }
}

class _MainBalanceCard extends StatelessWidget {
  final double balanceBrl, girocoins;
  const _MainBalanceCard({required this.balanceBrl, required this.girocoins});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
          _AnimatedBalance(value: balanceBrl),
          const SizedBox(height: 16),
          Container(height: 0.5, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.toll_rounded, color: Colors.white60, size: 15),
              const SizedBox(width: 6),
              Text('${girocoins.toStringAsFixed(0)} GiroCoins',
                  style: GoogleFonts.inter(
                      fontSize: 14, color: Colors.white.withOpacity(0.75))),
              const Spacer(),
              _CardAction(
                label: 'Depositar', icon: Icons.add_rounded,
                onTap: () => showModalBottomSheet(
                  context: context, isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const DepositSheet(),
                ),
              ),
              const SizedBox(width: 8),
              _CardAction(
                label: 'Transferir', icon: Icons.arrow_forward_rounded,
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

class _FrozenBalanceCard extends StatelessWidget {
  final double frozenBalance;
  const _FrozenBalanceCard({required this.frozenBalance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lock_rounded, color: AppColors.warning, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Saldo a receber',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                Text(
                  'R\$ ${frozenBalance.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary, size: 18),
        ],
      ),
    );
  }
}

// ── Animação de Contador de Saldo ──────────────────────────────────────────────
class _AnimatedBalance extends StatefulWidget {
  final double value;
  const _AnimatedBalance({required this.value});

  @override
  State<_AnimatedBalance> createState() => _AnimatedBalanceState();
}

class _AnimatedBalanceState extends State<_AnimatedBalance>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  double _prev = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _anim = Tween<double>(begin: 0, end: widget.value)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_AnimatedBalance old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _prev = old.value;
      _anim = Tween<double>(begin: _prev, end: widget.value)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Text(
        'R\$ ${_anim.value.toStringAsFixed(2).replaceAll('.', ',')}',
        style: GoogleFonts.inter(
          fontSize: 36, fontWeight: FontWeight.w800,
          color: Colors.white, letterSpacing: -1.0,
        ),
      ),
    );
  }
}

class _CardAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _CardAction({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── Card de Escrow Ativo ───────────────────────────────────────────────────────
class _EscrowActiveCard extends ConsumerStatefulWidget {
  final TransactionModel transaction;
  const _EscrowActiveCard({required this.transaction});

  @override
  ConsumerState<_EscrowActiveCard> createState() => _EscrowActiveCardState();
}

class _EscrowActiveCardState extends ConsumerState<_EscrowActiveCard> {
  bool _releasing = false;

  Future<void> _onConfirm() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfirmReleaseSheet(amount: widget.transaction.amount),
    );
    if (confirmed != true) return;

    setState(() => _releasing = true);
    HapticFeedback.mediumImpact();

    try {
      await ref.read(transactionsProvider.notifier).releaseEscrow(widget.transaction.id);
      if (mounted) {
        HapticFeedback.heavyImpact();
        _showReleaseSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _releasing = false);
    }
  }

  void _showReleaseSuccess() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReleaseSuccessSheet(amount: widget.transaction.amount),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_shipping_rounded, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Compra em andamento',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    Text(tx.trackingCode ?? 'Sem código',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Text(
                'R\$ ${tx.amount.toStringAsFixed(2).replaceAll('.', ',')}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _releasing ? null : _onConfirm,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _releasing
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Confirmar recebimento',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Lista de Histórico ─────────────────────────────────────────────────────────
class _TransactionList extends StatelessWidget {
  final List<TransactionModel> transactions;
  const _TransactionList({required this.transactions});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: List.generate(transactions.length, (i) {
          final tx = transactions[i];
          final isLast = i == transactions.length - 1;
          return _TransactionTile(transaction: tx, isLast: isLast);
        }),
      ),
    );
  }
}

class _TransactionTile extends ConsumerWidget {
  final TransactionModel transaction;
  final bool isLast;
  const _TransactionTile({required this.transaction, required this.isLast});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tx     = transaction;
    final userId = ref.read(currentUserIdProvider);
    final isBuyer = tx.buyerId == userId;
    final isCredit = !isBuyer && tx.status.isReleased;
    final color = isCredit ? AppColors.success : AppColors.textPrimary;
    final icon  = isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    final sign  = isCredit ? '+' : '-';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_statusLabel(tx.status),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    Text(_formatDate(tx.createdAt),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Text(
                '$sign R\$ ${tx.amount.toStringAsFixed(2).replaceAll('.', ',')}',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, indent: 66, endIndent: 16, color: AppColors.divider),
      ],
    );
  }

  String _statusLabel(TransactionStatus s) {
    const map = {
      TransactionStatus.paid:      'Pagamento em custódia',
      TransactionStatus.released:  'Pagamento liberado',
      TransactionStatus.cancelled: 'Cancelado',
      TransactionStatus.pending:   'Pendente',
      TransactionStatus.held:      'Retido',
    };
    return map[s] ?? 'Transação';
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Hoje, ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    if (diff.inDays == 1) return 'Ontem';
    return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
  }
}

// ── Sheets ─────────────────────────────────────────────────────────────────────
class _ConfirmReleaseSheet extends StatelessWidget {
  final double amount;
  const _ConfirmReleaseSheet({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_rounded, color: AppColors.success, size: 34),
          ),
          const SizedBox(height: 16),
          const Text('Confirmar recebimento?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(
            'Ao confirmar, R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')} serão liberados ao vendedor. Esta ação não pode ser desfeita.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Sim, recebi o produto'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _ReleaseSuccessSheet extends StatefulWidget {
  final double amount;
  const _ReleaseSuccessSheet({required this.amount});

  @override
  State<_ReleaseSuccessSheet> createState() => _ReleaseSuccessSheetState();
}

class _ReleaseSuccessSheetState extends State<_ReleaseSuccessSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 32, 24, MediaQuery.of(context).padding.bottom + 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: FadeTransition(
        opacity: _fade,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scale,
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: AppColors.success, size: 44),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Pagamento liberado!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(
              'R\$ ${widget.amount.toStringAsFixed(2).replaceAll('.', ',')} foram transferidos ao vendedor com sucesso.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Concluído'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Utilitários ────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary));
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.receipt_long_rounded, size: 40, color: AppColors.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 12),
          const Text('Nenhuma transação ainda',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _BalanceCardSkeleton extends StatelessWidget {
  const _BalanceCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.divider.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.error),
          SizedBox(width: 10),
          Text('Não foi possível carregar a carteira',
              style: TextStyle(color: AppColors.error, fontSize: 14)),
        ],
      ),
    );
  }
}
