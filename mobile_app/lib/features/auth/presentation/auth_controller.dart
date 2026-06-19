import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/failures.dart';
import '../../../core/storage/secure_storage.dart';
import '../../cart/presentation/cart_controller.dart';
import '../data/auth_repository.dart';
import '../../../core/network/auth_event.dart';
import '../domain/auth_user.dart';

class AuthState {
  final AsyncValue<AuthUser?> user;
  final String? error;

  AuthState({
    required this.user,
    this.error,
  });

  AuthState copyWith({
    AsyncValue<AuthUser?>? user,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final SecureStorage _storage;
  final Ref _ref;

  AuthNotifier(this._repository, this._storage, this._ref)
      : super(AuthState(user: const AsyncValue.data(null))) {
    init();
    
    // Listen to token expiration events from the network layer
    _ref.listen<bool>(authExpiredEventProvider, (previous, next) {
      if (next == true) {
        forceLogout();
        // Reset the event state back to false
        _ref.read(authExpiredEventProvider.notifier).state = false;
      }
    });
  }

  Future<void> init() async {
    state = state.copyWith(user: const AsyncValue.loading());
    try {
      final token = await _storage.getToken();
      final userMap = await _storage.getUser();
      if (token != null && userMap != null) {
        state = state.copyWith(user: AsyncValue.data(AuthUser.fromJson(userMap)));
      } else {
        state = state.copyWith(user: const AsyncValue.data(null));
      }
    } catch (e, stack) {
      state = state.copyWith(user: AsyncValue.error(e, stack));
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(user: const AsyncValue.loading(), error: null);
    try {
      final user = await _repository.login(email, password);
      state = state.copyWith(user: AsyncValue.data(user));
      return true;
    } on Failure catch (f) {
      state = state.copyWith(user: const AsyncValue.data(null), error: f.message);
      return false;
    } catch (e) {
      state = state.copyWith(user: const AsyncValue.data(null), error: e.toString());
      return false;
    }
  }

  Future<bool> register(String email, String username, String password, String role) async {
    state = state.copyWith(user: const AsyncValue.loading(), error: null);
    try {
      await _repository.register(email, username, password, role);
      // Automatically log in after registration
      return await login(email, password);
    } on Failure catch (f) {
      state = state.copyWith(user: const AsyncValue.data(null), error: f.message);
      return false;
    } catch (e) {
      state = state.copyWith(user: const AsyncValue.data(null), error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(user: const AsyncValue.loading());
    await _repository.logout();
    state = state.copyWith(user: const AsyncValue.data(null));
    
    // Clear cart state locally
    _ref.read(cartProvider.notifier).clearLocalCart();
  }

  void forceLogout() {
    state = AuthState(user: const AsyncValue.data(null));
    _ref.read(cartProvider.notifier).clearLocalCart();
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthNotifier(repository, storage, ref);
});
