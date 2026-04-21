import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/wallet/domain/transaction_model.dart';
import 'supabase_provider.dart';
import 'wallet_provider.dart';
import 'auth_provider.dart';

class TransactionsNotifier extends AsyncNotifier<List<TransactionModel>> {
  @override
  Future<List<TransactionModel>> build() => _fetch();

  Future<List<TransactionModel>> _fetch() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return [];

    final data = await ref.read(supabaseClientProvider)
        .from('transactions_escrow')
        .select()
        .or('buyer_id.eq.$userId,seller_id.eq.$userId')
        .order('created_at', ascending: false)
        .limit(30);

    return (data as List).map((e) => TransactionModel.fromJson(e)).toList();
  }

  /// Libera o escrow: feedback otimista + chamada à Edge Function
  Future<void> releaseEscrow(String transactionId) async {
    // Atualização otimista: marca como released localmente
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.map((tx) =>
      tx.id == transactionId ? tx.copyWith(status: TransactionStatus.released) : tx
    ).toList());

    try {
      final client = ref.read(supabaseClientProvider);
      final response = await client.functions.invoke(
        'release_escrow_funds',
        body: {'transaction_id': transactionId},
      );

      if (response.status != 200) {
        // Reverte e relança
        await refresh();
        throw Exception(response.data?['error'] ?? 'Falha ao liberar');
      }

      // Atualiza saldo da wallet (vendedor recebeu, comprador já estava atualizado)
      await ref.read(walletProvider.notifier).refresh();

    } catch (e) {
      await refresh();
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, List<TransactionModel>>(
  TransactionsNotifier.new,
);
