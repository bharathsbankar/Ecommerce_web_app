import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/failures.dart';
import '../../cart/presentation/cart_controller.dart';
import '../../catalog/presentation/catalog_controller.dart';
import '../data/order_repository.dart';
import '../domain/order.dart';

class OrderNotifier extends StateNotifier<AsyncValue<List<Order>>> {
  final OrderRepository _repository;
  final Ref _ref;

  OrderNotifier(this._repository, this._ref) : super(const AsyncValue.loading());

  Future<void> fetchOrders() async {
    state = const AsyncValue.loading();
    try {
      final orders = await _repository.getOrderHistory();
      state = AsyncValue.data(orders);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<CheckoutResult> checkout() async {
    try {
      final savedOrder = await _repository.checkout();
      
      // Update order history
      state.whenData((orders) {
        state = AsyncValue.data([savedOrder, ...orders]);
      });

      // Clear local cart since checkout clears it on server
      _ref.read(cartProvider.notifier).clearLocalCart();
      
      // Refresh catalog stock
      _ref.read(catalogProvider.notifier).fetchProducts();

      return CheckoutResult.success(savedOrder);
    } on Failure catch (f) {
      // Refresh cart and products lists to sync latest catalog state post-failure
      _ref.read(cartProvider.notifier).fetchCart();
      _ref.read(catalogProvider.notifier).fetchProducts();
      return CheckoutResult.failure(f.message);
    } catch (e) {
      return CheckoutResult.failure(e.toString());
    }
  }
}

class CheckoutResult {
  final Order? order;
  final String? errorMessage;
  final bool isSuccess;

  CheckoutResult.success(this.order)
      : errorMessage = null,
        isSuccess = true;

  CheckoutResult.failure(this.errorMessage)
      : order = null,
        isSuccess = false;
}

final orderProvider = StateNotifierProvider<OrderNotifier, AsyncValue<List<Order>>>((ref) {
  final repository = ref.watch(orderRepositoryProvider);
  return OrderNotifier(repository, ref);
});
