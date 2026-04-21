enum TransactionStatus { pending, paid, held, released, cancelled }

extension TransactionStatusX on TransactionStatus {
  static TransactionStatus fromString(String s) =>
      TransactionStatus.values.firstWhere((e) => e.name == s,
          orElse: () => TransactionStatus.pending);

  bool get isEscrowActive => this == TransactionStatus.paid;
  bool get isReleased     => this == TransactionStatus.released;
}

class TransactionModel {
  final String id;
  final String buyerId;
  final String sellerId;
  final String productId;
  final double amount;
  final TransactionStatus status;
  final String? trackingCode;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.productId,
    required this.amount,
    required this.status,
    this.trackingCode,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> j) => TransactionModel(
    id:           j['id'] as String,
    buyerId:      j['buyer_id'] as String,
    sellerId:     j['seller_id'] as String,
    productId:    j['product_id'] as String,
    amount:       (j['amount'] as num).toDouble(),
    status:       TransactionStatusX.fromString(j['status'] as String),
    trackingCode: j['tracking_code'] as String?,
    createdAt:    DateTime.parse(j['created_at'] as String),
  );

  TransactionModel copyWith({TransactionStatus? status}) => TransactionModel(
    id: id, buyerId: buyerId, sellerId: sellerId, productId: productId,
    amount: amount, trackingCode: trackingCode, createdAt: createdAt,
    status: status ?? this.status,
  );
}
