class WalletModel {
  final String id;
  final String userId;
  final double balanceBrl;
  final double balanceGirocoin;
  final double frozenBalance;

  const WalletModel({
    required this.id,
    required this.userId,
    required this.balanceBrl,
    required this.balanceGirocoin,
    required this.frozenBalance,
  });

  factory WalletModel.fromJson(Map<String, dynamic> j) => WalletModel(
    id:             j['id'] as String,
    userId:         j['user_id'] as String,
    balanceBrl:     (j['balance_brl'] as num).toDouble(),
    balanceGirocoin:(j['balance_girocoin'] as num).toDouble(),
    frozenBalance:  (j['frozen_balance'] as num).toDouble(),
  );

  WalletModel copyWith({double? balanceBrl, double? frozenBalance}) => WalletModel(
    id:             id,
    userId:         userId,
    balanceBrl:     balanceBrl ?? this.balanceBrl,
    balanceGirocoin: balanceGirocoin,
    frozenBalance:  frozenBalance ?? this.frozenBalance,
  );
}
