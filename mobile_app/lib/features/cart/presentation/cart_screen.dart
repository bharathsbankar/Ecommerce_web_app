import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/flipkart_scaffold.dart';
import '../../catalog/domain/product.dart';
import '../../catalog/presentation/catalog_controller.dart';
import '../../orders/presentation/order_controller.dart';
import 'cart_controller.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _isCheckingOut = false;

  Future<void> _handleCheckout() async {
    setState(() {
      _isCheckingOut = true;
    });

    // Simulate payment authorization processing overlay (2 seconds)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final result = await ref.read(orderProvider.notifier).checkout();

    setState(() {
      _isCheckingOut = false;
    });

    if (result.isSuccess) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: const [
                Icon(LucideIcons.checkCircle2, color: AppColors.emeraldGreen),
                SizedBox(width: 10),
                Text('Success!'),
              ],
            ),
            content: Text('Checkout completed successfully! Order ID: ${result.order?.id}'),
            actions: [
              TextButton(
                onPressed: () {
                  context.pop();
                  context.go('/history');
                },
                child: const Text('OK'),
              )
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: const [
                Icon(LucideIcons.alertTriangle, color: AppColors.errorRed),
                SizedBox(width: 10),
                Text('Checkout Failed'),
              ],
            ),
            content: Text(result.errorMessage ?? 'Saga rollback orchestration failed.'),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('DISMISS'),
              )
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final catalogState = ref.watch(catalogProvider);

    return FlipkartScaffold(
      title: 'Your Cart',
      body: Stack(
        children: [
          cartState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Text('Failed to load cart: $err'),
            ),
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.shoppingCart, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'Your cart is empty.\nReserve hot deals before they sell out!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textLight, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => context.go('/products'),
                        child: const Text('SHOP DEALS NOW'),
                      )
                    ],
                  ),
                );
              }

              final products = catalogState.value ?? [];

              double grandTotal = 0;
              for (final item in items) {
                final product = products.firstWhere(
                  (p) => p.id == item.productId,
                  orElse: () => Product(id: item.productId, name: 'Product #${item.productId}', description: '', price: 0, stockQuantity: 0),
                );
                grandTotal += product.price * item.quantity;
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final p = products.firstWhere(
                          (p) => p.id == item.productId,
                          orElse: () => Product(id: item.productId, name: 'Product #${item.productId}', description: '', price: 0, stockQuantity: 0),
                        );
                        final itemTotal = p.price * item.quantity;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey.shade100,
                                  child: const Center(child: Text('📦', style: TextStyle(fontSize: 28))),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Unit Price: ₹${p.price.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Qty control
                                          Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey.shade300),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              children: [
                                                GestureDetector(
                                                  onTap: () => ref.read(cartProvider.notifier).updateQuantity(p.id, item.quantity - 1),
                                                  child: const Padding(
                                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    child: Text('-', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                                  ),
                                                ),
                                                Text(
                                                  '${item.quantity}',
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                ),
                                                GestureDetector(
                                                  onTap: () => ref.read(cartProvider.notifier).updateQuantity(p.id, item.quantity + 1),
                                                  child: const Padding(
                                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    child: Text('+', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '₹${itemTotal.toStringAsFixed(2)}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          IconButton(
                                            icon: const Icon(LucideIcons.trash2, color: AppColors.errorRed, size: 18),
                                            onPressed: () => ref.read(cartProvider.notifier).removeFromCart(p.id),
                                          )
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom checkout panel
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(
                              '₹${grandTotal.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.flipkartBlue),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _handleCheckout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.flipkartYellow,
                            foregroundColor: AppColors.flipkartBlue,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'PLACE ORDER (BUY)',
                            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          
          // Secure Checkout overlay
          if (_isCheckingOut)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.darkNavy,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade800),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(
                        height: 48,
                        width: 48,
                        child: CircularProgressIndicator(color: AppColors.flipkartYellow, strokeWidth: 4),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Simulating Secure Payment...',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Verifying payment token via cryptographic rails, executing stock decrement, and clearing Redis holdings. Please wait.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
