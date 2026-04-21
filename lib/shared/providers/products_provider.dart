import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/marketplace/domain/product_model.dart';
import '../../features/marketplace/data/product_repository.dart';
import 'supabase_provider.dart';

// ── Repository provider ────────────────────────────────────────────────────────
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.read(supabaseClientProvider));
});

// ── Filtro de busca ────────────────────────────────────────────────────────────
class ProductFilter {
  final String query;
  final String? category;

  const ProductFilter({this.query = '', this.category});

  ProductFilter copyWith({String? query, String? category}) => ProductFilter(
    query:    query    ?? this.query,
    category: category == '__clear__' ? null : (category ?? this.category),
  );
}

final productFilterProvider = StateProvider<ProductFilter>((_) => const ProductFilter());

// ── Notifier principal ─────────────────────────────────────────────────────────
class ProductsNotifier extends AsyncNotifier<List<ProductModel>> {
  @override
  Future<List<ProductModel>> build() => _fetch(const ProductFilter());

  Future<List<ProductModel>> _fetch(ProductFilter filter) async {
    return ref.read(productRepositoryProvider).fetchProducts(
      query:    filter.query,
      category: filter.category,
    );
  }

  Future<void> applyFilter(ProductFilter filter) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(filter));
  }

  Future<void> refresh() async {
    final filter = ref.read(productFilterProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(filter));
  }
}

final productsProvider =
    AsyncNotifierProvider<ProductsNotifier, List<ProductModel>>(
  ProductsNotifier.new,
);

// ── Categorias disponíveis ─────────────────────────────────────────────────────
const productCategories = [
  'Eletrônicos',
  'Serviços',
  'Vouchers',
  'Moda',
  'Casa',
  'Saúde',
];
