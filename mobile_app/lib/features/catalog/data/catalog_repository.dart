import 'package:dio/dio.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../domain/product.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CatalogRepository {
  final Dio _dio;

  CatalogRepository(this._dio);

  Future<List<Product>> getProducts() async {
    try {
      final response = await _dio.get('/api/products');
      final list = response.data as List;
      return list.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data?['message'] ?? e.message ?? 'Failed to fetch products');
    } catch (e) {
      throw ServerFailure('An unexpected error occurred: $e');
    }
  }

  Future<Product> getProductById(int id) async {
    try {
      final response = await _dio.get('/api/products/$id');
      return Product.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data?['message'] ?? e.message ?? 'Failed to fetch product');
    } catch (e) {
      throw ServerFailure('An unexpected error occurred: $e');
    }
  }

  Future<Product> createProduct(String name, String? description, double price, int stock) async {
    try {
      final response = await _dio.post('/api/products', data: {
        'name': name,
        'description': description,
        'price': price,
        'stockQuantity': stock,
      });
      return Product.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data?['message'] ?? e.message ?? 'Failed to create product');
    } catch (e) {
      throw ServerFailure('An unexpected error occurred: $e');
    }
  }

  Future<Product> updateProduct(int id, String name, String? description, double price, int stock) async {
    try {
      final response = await _dio.put('/api/products/$id', data: {
        'name': name,
        'description': description,
        'price': price,
        'stockQuantity': stock,
      });
      return Product.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data?['message'] ?? e.message ?? 'Failed to update product');
    } catch (e) {
      throw ServerFailure('An unexpected error occurred: $e');
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await _dio.delete('/api/products/$id');
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data?['message'] ?? e.message ?? 'Failed to delete product');
    } catch (e) {
      throw ServerFailure('An unexpected error occurred: $e');
    }
  }
}

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return CatalogRepository(dio);
});
