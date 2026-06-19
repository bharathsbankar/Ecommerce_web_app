import 'package:dio/dio.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../domain/order.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrderRepository {
  final Dio _dio;

  OrderRepository(this._dio);

  Future<List<Order>> getOrderHistory() async {
    try {
      final response = await _dio.get('/api/orders/history');
      final list = response.data as List;
      return list.map((json) => Order.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data?['message'] ?? e.message ?? 'Failed to fetch order history');
    } catch (e) {
      throw ServerFailure('An unexpected error occurred: $e');
    }
  }

  Future<Order> checkout() async {
    try {
      final response = await _dio.post('/api/orders/checkout');
      return Order.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      // Custom parser for SAGA-rollback / checkout failures
      final responseData = e.response?.data;
      String errorMsg = 'Checkout failed';
      
      if (responseData is String && responseData.isNotEmpty) {
        errorMsg = responseData;
      } else if (responseData is Map && responseData.containsKey('message')) {
        errorMsg = responseData['message'].toString();
      } else if (e.message != null) {
        errorMsg = e.message!;
      }
      
      throw ServerFailure(errorMsg, statusCode: e.response?.statusCode);
    } catch (e) {
      throw ServerFailure('An unexpected error occurred during checkout: $e');
    }
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return OrderRepository(dio);
});
