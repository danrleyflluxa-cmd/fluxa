import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class DepositSheet extends StatefulWidget {
  const DepositSheet({super.key});

  @override
  State<DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends State<DepositSheet> {
  final _amountCtrl = TextEditingController();
  int _selectedMethod = 0; // 0=PIX, 1=TED

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            Text('Depositar',
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text('Escolha o método e o valor',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 24),

            // Método
            Row(
              children: [
                _MethodChip(label: 'PIX', selected: _selectedMethod == 0, onTap: () => setState(() => _selectedMethod = 0)),
                const SizedBox(width: 10),
                _MethodChip(label: 'TED', selected: _selectedMethod == 1, onTap: () => setState(() => _selectedMethod = 1)),
              ],
            ),
            const SizedBox(height: 20),

            // Valor
            TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              decoration: InputDecoration(
                prefixText: 'R\$ ',
                prefixStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                hintText: '0,00',
                hintStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.divider),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 8),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 20),

            // Info PIX
            if (_selectedMethod == 0)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Após confirmar, você receberá a chave PIX para realizar a transferência.',
                        style: TextStyle(fontSize: 12, color: AppColors.primary, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: integrar com gateway de pagamento
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Funcionalidade disponível em breve'),
                  behavior: SnackBarBehavior.floating,
                ));
              },
              child: const Text('Gerar cobrança'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _MethodChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600,
          color: selected ? Colors.white : AppColors.textSecondary,
        )),
      ),
    );
  }
}
