import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/catalog_repository.dart';
import '../domain/product.dart';

class CatalogNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  final CatalogRepository _repository;

  CatalogNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    state = const AsyncValue.loading();
    try {
      final products = await _repository.getProducts();
      state = AsyncValue.data(products);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Admin Actions to mutate state
  Future<bool> createProduct(String name, String? description, double price, int stock) async {
    try {
      final newProduct = await _repository.createProduct(name, description, price, stock);
      state.whenData((products) {
        state = AsyncValue.data([...products, newProduct]);
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateProduct(int id, String name, String? description, double price, int stock) async {
    try {
      final updatedProduct = await _repository.updateProduct(id, name, description, price, stock);
      state.whenData((products) {
        state = AsyncValue.data(products.map((p) => p.id == id ? updatedProduct : p).toList());
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteProduct(int id) async {
    try {
      await _repository.deleteProduct(id);
      state.whenData((products) {
        state = AsyncValue.data(products.where((p) => p.id != id).toList());
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}

final catalogProvider = StateNotifierProvider<CatalogNotifier, AsyncValue<List<Product>>>((ref) {
  final repository = ref.watch(catalogRepositoryProvider);
  return CatalogNotifier(repository);
});
