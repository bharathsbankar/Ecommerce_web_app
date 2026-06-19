import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/features/auth/domain/auth_user.dart';
import 'package:mobile_app/features/catalog/domain/product.dart';
import 'package:mobile_app/features/cart/domain/cart_item.dart';
import 'package:mobile_app/features/orders/domain/order.dart';

void main() {
  group('JSON Deserialization Tests', () {
    test('AuthUser fromJson parses role and attributes correctly', () {
      final json = {
        'id': 9,
        'email': 'admin@gmail.com',
        'username': 'admin',
        'role': 'admin',
      };
      
      final user = AuthUser.fromJson(json);
      
      expect(user.id, 9);
      expect(user.email, 'admin@gmail.com');
      expect(user.username, 'admin');
      expect(user.role, 'admin');
    });

    test('Product fromJson parses fields correctly', () {
      final json = {
        'id': 1,
        'name': 'iPhone 15 Pro',
        'description': '128GB, Blue Titanium',
        'price': 134900.0,
        'stockQuantity': 10,
      };
      
      final product = Product.fromJson(json);
      
      expect(product.id, 1);
      expect(product.name, 'iPhone 15 Pro');
      expect(product.description, '128GB, Blue Titanium');
      expect(product.price, 134900.0);
      expect(product.stockQuantity, 10);
    });

    test('CartItem fromJson parses fields correctly', () {
      final json = {
        'productId': 1,
        'quantity': 3,
      };
      
      final item = CartItem.fromJson(json);
      
      expect(item.productId, 1);
      expect(item.quantity, 3);
    });

    test('Order and OrderItems fromJson parse fields correctly', () {
      final json = {
        'id': 12,
        'userId': 1,
        'grandTotal': 269800.0,
        'createdAt': '2026-06-19T20:00:00Z',
        'items': [
          {
            'id': 15,
            'productId': 1,
            'quantity': 2,
            'perUnitPrice': 134900.0,
            'totalPrice': 269800.0,
          }
        ]
      };
      
      final order = Order.fromJson(json);
      
      expect(order.id, 12);
      expect(order.userId, 1);
      expect(order.grandTotal, 269800.0);
      expect(order.createdAt, '2026-06-19T20:00:00Z');
      expect(order.items.length, 1);
      expect(order.items.first.id, 15);
      expect(order.items.first.productId, 1);
      expect(order.items.first.quantity, 2);
      expect(order.items.first.perUnitPrice, 134900.0);
      expect(order.items.first.totalPrice, 269800.0);
    });
  });
}
