import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/wallet/data/wallet_model.dart';
import 'supabase_provider.dart';
import 'auth_provider.dart';

class WalletNotifier extends AsyncNotifier<WalletModel?> {
  @override
  Future<WalletModel?> build() async => _fetch();

  Future<WalletModel?> _fetch() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return null;

    final data = await ref.read(supabaseClientProvider)
        .from('wallets')
        .select()
        .eq('user_id', userId)
        .single();

    return WalletModel.fromJson(data);
  }

  // Atualização otimista: desconta localmente antes da resposta do servidor
  void deductOptimistic(double amount) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      balanceBrl: current.balanceBrl - amount,
    ));
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final walletProvider = AsyncNotifierProvider<WalletNotifier, WalletModel?>(
  WalletNotifier.new,
);
