import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/providers/escrow_provider.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../domain/product_model.dart';

class ProductDetailPage extends ConsumerStatefulWidget {
  final ProductModel product;
  const ProductDetailPage({super.key, required this.product});

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  int _currentImage = 0;

  @override
  Widget build(BuildContext context) {
    final escrow = ref.watch(escrowProvider);

    // Escuta mudança de status para abrir o bottom sheet
    ref.listen<EscrowState>(escrowProvider, (prev, next) {
      if (next.status == EscrowStatus.success) {
        _showSuccessSheet(next.trackingCode!);
      } else if (next.status == EscrowStatus.error) {
        _showErrorSnack(next.errorMessage ?? 'Erro na compra');
      }
    });

    final p = widget.product;
    final hasImages = p.imagesUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _BlurButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.pop(context),
        ),
        actions: [
          _BlurButton(
            icon: Icons.share_rounded,
            onTap: () => Share.share(
              '${widget.product.title}\nR\$ ${widget.product.priceBrl.toStringAsFixed(2).replaceAll('.', ',')}\n\nCompre com segurança pela Garantia Fluxa.',
              subject: widget.product.title,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          // ── Conteúdo scrollável ──────────────────────────────────────────
          CustomScrollView(
            slivers: [
              // Galeria de imagens
              SliverToBoxAdapter(
                child: _ImageGallery(
                  images: hasImages ? p.imagesUrl : [],
                  currentIndex: _currentImage,
                  onPageChanged: (i) => setState(() => _currentImage = i),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 140),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Categoria
                    Text(p.category.toUpperCase(),
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700,
                            color: AppColors.primary, letterSpacing: 1.4)),
                    const SizedBox(height: 8),
                    Text(p.title,
                        style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary, letterSpacing: -0.5)),
                    const SizedBox(height: 8),
                    Text(
                      'R\$ ${p.priceBrl.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700,
                          color: AppColors.primary, letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 20),
                    // Garantia Fluxa
                    const _FluxaGuaranteeCard(),
                    const SizedBox(height: 24),
                    // Descrição
                    const Text('Descrição',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Text(p.description,
                        style: const TextStyle(fontSize: 15, color: AppColors.textSecondary,
                            height: 1.6)),
                    const SizedBox(height: 24),
                    // Estoque
                    _StockBadge(quantity: p.stockQuantity),
                  ]),
                ),
              ),
            ],
          ),

          // ── Botão fixo no rodapé com blur ────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _BuyFooter(
              price: p.priceBrl,
              isLoading: escrow.status == EscrowStatus.loading,
              onBuy: () => _onBuyTapped(),
            ),
          ),
        ],
      ),
    );
  }

  void _onBuyTapped() {
    final wallet = ref.read(walletProvider).valueOrNull;
    final p = widget.product;

    if (wallet == null) {
      _showErrorSnack('Carteira não carregada');
      return;
    }
    if (wallet.balanceBrl < p.priceBrl) {
      _showErrorSnack('Saldo insuficiente para esta compra');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfirmSheet(
        product: p,
        balance: wallet.balanceBrl,
        onConfirm: () {
          Navigator.pop(context);
          ref.read(escrowProvider.notifier).purchase(
            productId: p.id,
            sellerId:  p.sellerId,
            amount:    p.priceBrl,
          );
        },
      ),
    );
  }

  void _showSuccessSheet(String trackingCode) {
    ref.read(escrowProvider.notifier).reset();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => _SuccessSheet(trackingCode: trackingCode),
    );
  }

  void _showErrorSnack(String message) {
    ref.read(escrowProvider.notifier).reset();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ── Galeria de Imagens ─────────────────────────────────────────────────────────
class _ImageGallery extends StatelessWidget {
  final List<String> images;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  const _ImageGallery({required this.images, required this.currentIndex, required this.onPageChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 360,
      child: Stack(
        children: [
          images.isEmpty
              ? Container(
                  color: AppColors.divider,
                  child: const Center(child: Icon(Icons.image_rounded, size: 64, color: AppColors.textSecondary)),
                )
              : PageView.builder(
                  itemCount: images.length,
                  onPageChanged: onPageChanged,
                  itemBuilder: (_, i) => Image.network(
                    images[i],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: AppColors.divider),
                  ),
                ),
          // Indicadores
          if (images.length > 1)
            Positioned(
              bottom: 16, left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == currentIndex ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == currentIndex ? AppColors.primary : Colors.white54,
                    borderRadius: BorderRadius.circular(3),
                  ),
                )),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Garantia Fluxa ─────────────────────────────────────────────────────────────
class _FluxaGuaranteeCard extends StatelessWidget {
  const _FluxaGuaranteeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Garantia Fluxa', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                SizedBox(height: 2),
                Text(
                  'Seu pagamento fica protegido até você confirmar o recebimento. Só então o vendedor recebe.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Badge de Estoque ───────────────────────────────────────────────────────────
class _StockBadge extends StatelessWidget {
  final int quantity;
  const _StockBadge({required this.quantity});

  @override
  Widget build(BuildContext context) {
    final isLow = quantity <= 5;
    return Row(
      children: [
        Icon(
          isLow ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
          size: 16,
          color: isLow ? AppColors.warning : AppColors.success,
        ),
        const SizedBox(width: 6),
        Text(
          isLow ? 'Apenas $quantity em estoque' : '$quantity disponíveis',
          style: TextStyle(
            fontSize: 13,
            color: isLow ? AppColors.warning : AppColors.success,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Botão Blur no AppBar ───────────────────────────────────────────────────────
class _BlurButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _BlurButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 18, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

// ── Footer de Compra com Blur ──────────────────────────────────────────────────
class _BuyFooter extends StatelessWidget {
  final double price;
  final bool isLoading;
  final VoidCallback onBuy;

  const _BuyFooter({required this.price, required this.isLoading, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.88),
            border: const Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Total', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text(
                    'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: isLoading ? null : onBuy,
                  child: isLoading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Text('Comprar agora'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sheet de Confirmação ───────────────────────────────────────────────────────
class _ConfirmSheet extends StatelessWidget {
  final ProductModel product;
  final double balance;
  final VoidCallback onConfirm;

  const _ConfirmSheet({required this.product, required this.balance, required this.onConfirm});

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          const Text('Confirmar compra',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          _ConfirmRow(label: 'Produto', value: product.title),
          _ConfirmRow(
            label: 'Valor',
            value: 'R\$ ${product.priceBrl.toStringAsFixed(2).replaceAll('.', ',')}',
            valueColor: AppColors.primary,
          ),
          _ConfirmRow(
            label: 'Saldo após compra',
            value: 'R\$ ${(balance - product.priceBrl).toStringAsFixed(2).replaceAll('.', ',')}',
          ),
          const SizedBox(height: 8),
          const _FluxaGuaranteeCard(),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: onConfirm, child: const Text('Confirmar e pagar')),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _ConfirmRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}

// ── Sheet de Sucesso com Check Animado ────────────────────────────────────────
class _SuccessSheet extends StatefulWidget {
  final String trackingCode;
  const _SuccessSheet({required this.trackingCode});

  @override
  State<_SuccessSheet> createState() => _SuccessSheetState();
}

class _SuccessSheetState extends State<_SuccessSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 32, 24, MediaQuery.of(context).padding.bottom + 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Check animado
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
          const Text('Compra realizada!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(
            'Seu pagamento está protegido pela Garantia Fluxa.\nCódigo: ${widget.trackingCode}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navegar para carteira — integrar com router
            },
            child: const Text('Ver na Carteira'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            child: const Text('Continuar comprando',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}
