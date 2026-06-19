import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../catalog/presentation/catalog_controller.dart';
import '../data/cart_repository.dart';
import '../domain/cart_item.dart';

class CartNotifier extends StateNotifier<AsyncValue<List<CartItem>>> {
  final CartRepository _repository;
  final Ref _ref;

  CartNotifier(this._repository, this._ref) : super(const AsyncValue.loading());

  Future<void> fetchCart() async {
    try {
      final items = await _repository.getCart();
      state = AsyncValue.data(items);
      _ref.read(cartTimerProvider.notifier).syncWithCart(items);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> updateQuantity(int productId, int quantity) async {
    try {
      await _repository.updateCart(productId, quantity);
      
      // Reset reservation timer
      _ref.read(cartTimerProvider.notifier).resetTimer();

      await fetchCart();
      
      // Refresh product stock display
      _ref.read(catalogProvider.notifier).fetchProducts();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeFromCart(int productId) async {
    try {
      await _repository.removeFromCart(productId);
      await fetchCart();
      
      // Refresh product stock display
      _ref.read(catalogProvider.notifier).fetchProducts();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> clearCart() async {
    try {
      await _repository.clearCart();
      state = const AsyncValue.data([]);
      _ref.read(cartTimerProvider.notifier).cancelTimer();
      _ref.read(catalogProvider.notifier).fetchProducts();
    } catch (_) {}
  }

  void clearLocalCart() {
    state = const AsyncValue.data([]);
    _ref.read(cartTimerProvider.notifier).cancelTimer();
  }
}

class CartTimerNotifier extends StateNotifier<int?> {
  Timer? _timer;
  final Ref _ref;

  CartTimerNotifier(this._ref) : super(null);

  void syncWithCart(List<CartItem> items) {
    if (items.isNotEmpty) {
      if (state == null) {
        resetTimer();
      }
    } else {
      cancelTimer();
    }
  }

  void resetTimer() {
    _timer?.cancel();
    state = 300; // 5 minutes
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state == null || state! <= 1) {
        state = 0;
        cancelTimer();
        // Clear cart automatically on expiry
        _ref.read(cartProvider.notifier).clearCart();
      } else {
        state = state! - 1;
      }
    });
  }

  void cancelTimer() {
    _timer?.cancel();
    _timer = null;
    state = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, AsyncValue<List<CartItem>>>((ref) {
  final repository = ref.watch(cartRepositoryProvider);
  return CartNotifier(repository, ref);
});

final cartTimerProvider = StateNotifierProvider<CartTimerNotifier, int?>((ref) {
  return CartTimerNotifier(ref);
});
