import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/providers/products_provider.dart';
import '../../domain/product_model.dart';
import 'product_detail_page.dart';

class MarketplacePage extends ConsumerStatefulWidget {
  const MarketplacePage({super.key});

  @override
  ConsumerState<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends ConsumerState<MarketplacePage> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final current = ref.read(productFilterProvider);
      final next    = current.copyWith(query: value);
      ref.read(productFilterProvider.notifier).state = next;
      ref.read(productsProvider.notifier).applyFilter(next);
    });
  }

  void _onCategory(String? category) {
    final current = ref.read(productFilterProvider);
    // toggle: mesma categoria desmarca
    final next = current.copyWith(
      category: current.category == category ? '__clear__' : category,
    );
    ref.read(productFilterProvider.notifier).state = next;
    ref.read(productsProvider.notifier).applyFilter(next);
  }

  @override
  Widget build(BuildContext context) {
    final filter       = ref.watch(productFilterProvider);
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          // ── SliverAppBar com SearchBar ─────────────────────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.background,
            expandedHeight: 120,
            collapsedHeight: 60,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              title: _SearchBar(
                controller: _searchCtrl,
                onChanged: _onSearch,
              ),
              expandedTitleScale: 1,
            ),
            title: null,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(0),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: _CategoryChips(
                  selected: filter.category,
                  onSelect: _onCategory,
                ),
              ),
            ),
          ),

          // ── Conteúdo ───────────────────────────────────────────────────────
          productsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: _ErrorState(onRetry: () => ref.read(productsProvider.notifier).refresh()),
            ),
            data: (products) {
              if (products.isEmpty) {
                return SliverFillRemaining(
                  child: _EmptyState(hasFilter: filter.query.isNotEmpty || filter.category != null),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:     2,
                    mainAxisSpacing:    12,
                    crossAxisSpacing:   12,
                    childAspectRatio:   0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _ProductCard(
                      product: products[i],
                      onTap: () => Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => ProductDetailPage(product: products[i]),
                        ),
                      ),
                    ),
                    childCount: products.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Search Bar ─────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CupertinoSearchTextField(
      controller:  controller,
      onChanged:   onChanged,
      placeholder: 'Buscar produtos...',
      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
      backgroundColor: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      prefixIcon: const Icon(CupertinoIcons.search, size: 18, color: AppColors.textSecondary),
    );
  }
}

// ── Category Chips ─────────────────────────────────────────────────────────────
class _CategoryChips extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;

  const _CategoryChips({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: productCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat        = productCategories[i];
          final isSelected = selected == cat;
          return GestureDetector(
            onTap: () => onSelect(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.divider,
                ),
              ),
              child: Text(
                cat,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Product Card ───────────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    product.imagesUrl.isNotEmpty
                        ? Image.network(
                            product.imagesUrl.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _ImagePlaceholder(),
                          )
                        : _ImagePlaceholder(),
                    // Selo Garantia Fluxa
                    Positioned(
                      top: 8, left: 8,
                      child: _FluxaBadge(),
                    ),
                  ],
                ),
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary, height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'R\$ ${product.priceBrl.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.background,
    child: const Center(
      child: Icon(CupertinoIcons.photo, size: 32, color: AppColors.divider),
    ),
  );
}

class _FluxaBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(CupertinoIcons.checkmark_shield_fill, size: 10, color: AppColors.primary),
          SizedBox(width: 3),
          Text('Fluxa', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ],
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  const _EmptyState({required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.bag, size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            hasFilter ? 'Nenhum produto encontrado' : 'O marketplace está vazio',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            hasFilter
                ? 'Tente outros termos ou remova os filtros.'
                : 'Seja o primeiro a publicar um produto\ne alcance toda a rede Fluxa.',
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ),
          if (!hasFilter) ...[
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(CupertinoIcons.add, size: 18),
              label: const Text('Publicar produto'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 48),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(CupertinoIcons.exclamationmark_circle, size: 40, color: AppColors.textSecondary),
        const SizedBox(height: 12),
        const Text('Não foi possível carregar os produtos',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        TextButton(onPressed: onRetry, child: const Text('Tentar novamente')),
      ],
    );
  }
}
