class ProductModel {
  final String id;
  final String sellerId;
  final String title;
  final String description;
  final double priceBrl;
  final String category;
  final List<String> imagesUrl;
  final int stockQuantity;

  const ProductModel({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.priceBrl,
    required this.category,
    required this.imagesUrl,
    required this.stockQuantity,
  });

  factory ProductModel.fromJson(Map<String, dynamic> j) => ProductModel(
    id:            j['id'] as String,
    sellerId:      j['seller_id'] as String,
    title:         j['title'] as String,
    description:   j['description'] as String? ?? '',
    priceBrl:      (j['price_brl'] as num).toDouble(),
    category:      j['category'] as String,
    imagesUrl:     List<String>.from(j['images_url'] ?? []),
    stockQuantity: j['stock_quantity'] as int,
  );
}
