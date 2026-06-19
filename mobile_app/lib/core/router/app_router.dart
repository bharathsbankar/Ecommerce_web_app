import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/catalog/presentation/products_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/orders/presentation/order_history_screen.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/dev_settings/presentation/dev_settings_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) {
      notifyListeners();
    });
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final routerNotifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/products',
    refreshListenable: routerNotifier,
    redirect: (context, state) {
      // Resolve current user authentication status
      final user = authState.user.value;
      final isAuthLoading = authState.user.isLoading;
      
      if (isAuthLoading) return null;

      final path = state.matchedLocation;
      final isLoggingIn = path == '/login' || path == '/register' || path == '/dev_settings';

      if (user == null) {
        // Gated routes for anonymous users
        if (!isLoggingIn) return '/login';
      } else {
        // Redirect logged-in users away from auth pages
        if (path == '/login' || path == '/register') {
          return user.role == 'admin' ? '/admin' : '/products';
        }
        // Gated routes for admins only
        if (path == '/admin' && user.role != 'admin') {
          return '/products';
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/products',
        builder: (context, state) => const ProductsScreen(),
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const OrderHistoryScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/dev_settings',
        builder: (context, state) => const DevSettingsScreen(),
      ),
    ],
  );
});
