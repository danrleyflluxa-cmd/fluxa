import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/product_model.dart';

class ProductRepository {
  final SupabaseClient _client;
  const ProductRepository(this._client);

  Future<List<ProductModel>> fetchProducts({
    String query = '',
    String? category,
    int limit = 40,
    int offset = 0,
  }) async {
    var q = _client
        .from('products')
        .select()
        .eq('is_active', true);

    if (category != null) q = q.eq('category', category);
    if (query.isNotEmpty) q = q.ilike('title', '%$query%');

    final data = await q
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1)
        .timeout(const Duration(seconds: 10));

    return (data as List).map((e) => ProductModel.fromJson(e)).toList();
  }

  Future<ProductModel> fetchById(String id) async {
    final data = await _client
        .from('products')
        .select()
        .eq('id', id)
        .single()
        .timeout(const Duration(seconds: 10));
    return ProductModel.fromJson(data);
  }

  Future<void> createProduct(Map<String, dynamic> payload) async {
    await _client.from('products').insert(payload);
  }

  Future<void> updateProduct(String id, Map<String, dynamic> payload) async {
    await _client.from('products').update(payload).eq('id', id);
  }

  Future<void> deactivateProduct(String id) async {
    await _client.from('products').update({'is_active': false}).eq('id', id);
  }
}
