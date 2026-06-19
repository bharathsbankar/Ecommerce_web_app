import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/flipkart_scaffold.dart';
import '../../cart/domain/cart_item.dart';
import '../../cart/presentation/cart_controller.dart';
import 'catalog_controller.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  // Local quantity selections for items NOT yet in the cart
  final Map<int, int> _selectedQuantities = {};

  @override
  void initState() {
    super.initState();
    // Hydrate cart data on page load
    Future.microtask(() {
      ref.read(cartProvider.notifier).fetchCart();
    });
  }

  int _getGridQty(int productId) {
    return _selectedQuantities[productId] ?? 1;
  }

  void _incrementGridQty(int productId, int maxStock) {
    final current = _getGridQty(productId);
    if (current < maxStock) {
      setState(() {
        _selectedQuantities[productId] = current + 1;
      });
    }
  }

  void _decrementGridQty(int productId) {
    final current = _getGridQty(productId);
    if (current > 1) {
      setState(() {
        _selectedQuantities[productId] = current - 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(catalogProvider);
    final cartState = ref.watch(cartProvider);

    return FlipkartScaffold(
      title: 'Store Deals',
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.refreshCw),
          onPressed: () {
            ref.read(catalogProvider.notifier).fetchProducts();
            ref.read(cartProvider.notifier).fetchCart();
          },
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(catalogProvider.notifier).fetchProducts();
          await ref.read(cartProvider.notifier).fetchCart();
        },
        child: catalogState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.alertTriangle, size: 48, color: AppColors.errorRed),
                  const SizedBox(height: 12),
                  Text('Failed to load catalog: $err', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.read(catalogProvider.notifier).fetchProducts(),
                    child: const Text('RETRY'),
                  )
                ],
              ),
            ),
          ),
          data: (products) {
            if (products.isEmpty) {
              return const Center(child: Text('No hot deals currently active.'));
            }

            final cartItems = cartState.value ?? [];

            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.65,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final p = products[index];
                final cartItem = cartItems.firstWhere(
                  (item) => item.productId == p.id,
                  orElse: () => const CartItem(productId: 0, quantity: 0),
                );
                
                final isInCart = cartItem.productId != 0;
                final isOutOfStock = p.stockQuantity <= 0;
                final selectedQty = _getGridQty(p.id);

                return Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Thumbnail
                      Expanded(
                        child: Container(
                          color: Colors.grey.shade100,
                          child: const Center(
                            child: Text('📦', style: TextStyle(fontSize: 48)),
                          ),
                        ),
                      ),
                      
                      // Details
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              p.description ?? '',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${p.price.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 8),

                            // Stock Indicator
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Stock:', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: isOutOfStock ? Colors.red.shade50 : Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Text(
                                    isOutOfStock ? 'OUT OF STOCK' : '${p.stockQuantity} Left',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: isOutOfStock ? AppColors.errorRed : AppColors.emeraldGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Action controllers
                            if (isInCart)
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2FE), // Blue-100
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () => ref.read(cartProvider.notifier).updateQuantity(p.id, cartItem.quantity - 1),
                                      child: const Icon(LucideIcons.minus, size: 14, color: AppColors.flipkartBlue),
                                    ),
                                    Text(
                                      '${cartItem.quantity}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                    GestureDetector(
                                      onTap: cartItem.quantity >= p.stockQuantity + cartItem.quantity
                                          ? null
                                          : () => ref.read(cartProvider.notifier).updateQuantity(p.id, cartItem.quantity + 1),
                                      child: Icon(
                                        LucideIcons.plus,
                                        size: 14,
                                        color: cartItem.quantity >= p.stockQuantity + cartItem.quantity
                                            ? Colors.grey
                                            : AppColors.flipkartBlue,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Row(
                                children: [
                                  // Quantity controller
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        GestureDetector(
                                          onTap: isOutOfStock ? null : () => _decrementGridQty(p.id),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                            child: Icon(LucideIcons.minus, size: 12, color: isOutOfStock ? Colors.grey : AppColors.textDark),
                                          ),
                                        ),
                                        Text(
                                          '${isOutOfStock ? 0 : selectedQty}',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                        GestureDetector(
                                          onTap: isOutOfStock || selectedQty >= p.stockQuantity
                                              ? null
                                              : () => _incrementGridQty(p.id, p.stockQuantity),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                            child: Icon(
                                              LucideIcons.plus,
                                              size: 12,
                                              color: isOutOfStock || selectedQty >= p.stockQuantity ? Colors.grey : AppColors.textDark,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  
                                  // Buy button
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: isOutOfStock
                                          ? null
                                          : () => ref.read(cartProvider.notifier).updateQuantity(p.id, selectedQty),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        backgroundColor: AppColors.flipkartYellow,
                                        disabledBackgroundColor: Colors.grey.shade200,
                                      ),
                                      child: const Text('ADD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
