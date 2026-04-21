import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/providers/supabase_provider.dart';

class TransferSheet extends ConsumerStatefulWidget {
  const TransferSheet({super.key});

  @override
  ConsumerState<TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends ConsumerState<TransferSheet> {
  final _recipientCtrl = TextEditingController();
  final _amountCtrl    = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _recipientCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final amountStr = _amountCtrl.text.replaceAll(',', '.');
    final amount    = double.tryParse(amountStr);
    final recipient = _recipientCtrl.text.trim();

    if (recipient.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Preencha todos os campos corretamente'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final wallet = ref.read(walletProvider).valueOrNull;
    if (wallet == null || wallet.balanceBrl < amount) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Saldo insuficiente'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _sending = true);
    HapticFeedback.mediumImpact();

    try {
      // Chama Edge Function de transferência
      final client = ref.read(supabaseClientProvider);
      final response = await client.functions.invoke(
        'transfer_balance',
        body: {'recipient_email': recipient, 'amount': amount},
      );

      if (response.status != 200) {
        final err = response.data?['error'] ?? 'Falha na transferência';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(err),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ));
        }
        return;
      }

      final recipientName = response.data['recipient_name'] as String;
      await ref.read(walletProvider.notifier).refresh();

      if (mounted) {
        HapticFeedback.heavyImpact();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')} transferidos para $recipientName'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = ref.watch(walletProvider).valueOrNull?.balanceBrl ?? 0.0;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 4,
                decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Transferir',
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text('Disponível: R\$ ${balance.toStringAsFixed(2).replaceAll('.', ',')}',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 24),

            // Destinatário
            TextFormField(
              controller: _recipientCtrl,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.inter(fontSize: 15, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'E-mail do destinatário',
                prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.textSecondary, size: 20),
              ),
            ),
            const SizedBox(height: 12),

            // Valor
            TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
              style: GoogleFonts.inter(fontSize: 15, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Valor (R\$)',
                prefixIcon: Icon(Icons.attach_money_rounded, color: AppColors.textSecondary, size: 20),
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _sending ? null : _send,
              child: _sending
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Confirmar transferência'),
            ),
          ],
        ),
      ),
    );
  }
}
