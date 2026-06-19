import 'package:dio/dio.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../domain/cart_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartRepository {
  final Dio _dio;

  CartRepository(this._dio);

  Future<List<CartItem>> getCart() async {
    try {
      final response = await _dio.get('/api/cart');
      final itemsList = response.data['items'] as List? ?? [];
      return itemsList.map((json) => CartItem.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data?['error'] ?? e.message ?? 'Failed to fetch cart');
    } catch (e) {
      throw ServerFailure('An unexpected error occurred: $e');
    }
  }

  Future<void> updateCart(int productId, int quantity) async {
    try {
      await _dio.post('/api/cart', data: {
        'productId': productId,
        'quantity': quantity,
      });
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data?['error'] ?? e.message ?? 'Failed to update cart');
    } catch (e) {
      throw ServerFailure('An unexpected error occurred: $e');
    }
  }

  Future<void> removeFromCart(int productId) async {
    try {
      await _dio.delete('/api/cart/$productId');
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data?['error'] ?? e.message ?? 'Failed to remove item from cart');
    } catch (e) {
      throw ServerFailure('An unexpected error occurred: $e');
    }
  }

  Future<void> clearCart() async {
    try {
      await _dio.delete('/api/cart');
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data?['error'] ?? e.message ?? 'Failed to clear cart');
    } catch (e) {
      throw ServerFailure('An unexpected error occurred: $e');
    }
  }
}

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return CartRepository(dio);
});
