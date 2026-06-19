import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/cart/presentation/cart_controller.dart';
import '../theme/app_theme.dart';

class FlipkartScaffold extends ConsumerWidget {
  final Widget body;
  final String title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const FlipkartScaffold({
    super.key,
    required this.body,
    required this.title,
    this.actions,
    this.floatingActionButton,
  });

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user.value;
    final timerVal = ref.watch(cartTimerProvider);

    // Compute active tab index based on GoRouter matched path
    final route = GoRouterState.of(context).matchedLocation;
    int currentIndex = 0;
    if (route == '/products') currentIndex = 0;
    if (route == '/cart') currentIndex = 1;
    if (route == '/history') currentIndex = 2;
    if (route == '/admin') currentIndex = 3;

    // Define navigation items
    final List<BottomNavigationBarItem> navItems = [
      const BottomNavigationBarItem(
        icon: Icon(LucideIcons.package),
        label: 'Store',
      ),
      const BottomNavigationBarItem(
        icon: Icon(LucideIcons.shoppingCart),
        label: 'Cart',
      ),
      const BottomNavigationBarItem(
        icon: Icon(LucideIcons.shoppingBag),
        label: 'Orders',
      ),
    ];

    if (user?.role == 'admin') {
      navItems.add(const BottomNavigationBarItem(
        icon: Icon(LucideIcons.settings),
        label: 'Admin',
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            if (user != null)
              Text(
                'Hello, ${user.username} (${user.role})',
                style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          ...?actions,
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            onPressed: () {
              ref.read(authStateProvider.notifier).logout();
              context.go('/login');
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex >= navItems.length ? 0 : currentIndex,
        selectedItemColor: AppColors.flipkartBlue,
        unselectedItemColor: AppColors.textLight,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: navItems,
        onTap: (index) {
          if (index == 0) context.go('/products');
          if (index == 1) context.go('/cart');
          if (index == 2) context.go('/history');
          if (index == 3 && user?.role == 'admin') context.go('/admin');
        },
      ),
      floatingActionButton: floatingActionButton,
      body: Column(
        children: [
          // Client-side Cart soft-reservation countdown banner
          if (timerVal != null && timerVal > 0)
            Container(
              color: const Color(0xFFFEF9C3), // Yellow-50
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.clock, size: 16, color: AppColors.warningOrange),
                  const SizedBox(width: 8),
                  const Text(
                    'Purchase within: ',
                    style: TextStyle(fontSize: 12, color: Colors.brown, fontWeight: FontWeight.w500),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Text(
                      _formatTime(timerVal),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
