import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_provider.dart';
import 'wallet_provider.dart';

enum EscrowStatus { idle, loading, success, error }

class EscrowState {
  final EscrowStatus status;
  final String? trackingCode;
  final String? errorMessage;

  const EscrowState({
    this.status = EscrowStatus.idle,
    this.trackingCode,
    this.errorMessage,
  });

  EscrowState copyWith({EscrowStatus? status, String? trackingCode, String? errorMessage}) =>
      EscrowState(
        status:       status ?? this.status,
        trackingCode: trackingCode ?? this.trackingCode,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class EscrowNotifier extends Notifier<EscrowState> {
  @override
  EscrowState build() => const EscrowState();

  Future<void> purchase({
    required String productId,
    required String sellerId,
    required double amount,
  }) async {
    state = state.copyWith(status: EscrowStatus.loading);

    // Atualização otimista do saldo
    ref.read(walletProvider.notifier).deductOptimistic(amount);

    try {
      final client = ref.read(supabaseClientProvider);
      final response = await client.functions.invoke(
        'process_escrow_purchase',
        body: {
          'product_id': productId,
          'seller_id':  sellerId,
          'amount':     amount,
        },
      );

      if (response.status != 200) {
        final err = response.data?['error'] ?? 'Erro desconhecido';
        // Reverte atualização otimista
        await ref.read(walletProvider.notifier).refresh();
        state = state.copyWith(status: EscrowStatus.error, errorMessage: err);
        return;
      }

      final trackingCode = response.data?['transaction']?['tracking_code'] as String? ?? '';
      // Confirma saldo real do servidor
      await ref.read(walletProvider.notifier).refresh();
      state = state.copyWith(status: EscrowStatus.success, trackingCode: trackingCode);

    } catch (e) {
      await ref.read(walletProvider.notifier).refresh();
      state = state.copyWith(status: EscrowStatus.error, errorMessage: e.toString());
    }
  }

  void reset() => state = const EscrowState();
}

final escrowProvider = NotifierProvider<EscrowNotifier, EscrowState>(
  EscrowNotifier.new,
);
