import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NetworkConfigData {
  final String host;
  final String port;

  const NetworkConfigData({required this.host, required this.port});

  NetworkConfigData copyWith({String? host, String? port}) {
    return NetworkConfigData(
      host: host ?? this.host,
      port: port ?? this.port,
    );
  }

  String get baseUrl => 'http://$host:$port';
}

class NetworkConfigNotifier extends StateNotifier<NetworkConfigData> {
  final SharedPreferences _prefs;

  static const _hostKey = 'dev_api_host';
  static const _portKey = 'dev_api_port';
  static const _historyKey = 'dev_api_host_history';

  NetworkConfigNotifier(this._prefs)
      : super(NetworkConfigData(
          host: _prefs.getString(_hostKey) ?? '10.0.2.2',
          port: _prefs.getString(_portKey) ?? '8080',
        ));

  Future<void> updateConfig(String host, String port) async {
    await _prefs.setString(_hostKey, host);
    await _prefs.setString(_portKey, port);
    state = NetworkConfigData(host: host, port: port);
    
    // Save to history list
    List<String> history = _prefs.getStringList(_historyKey) ?? [];
    if (!history.contains(host)) {
      history.insert(0, host);
      if (history.length > 3) history = history.sublist(0, 3);
      await _prefs.setStringList(_historyKey, history);
    }
  }

  List<String> getHostHistory() {
    return _prefs.getStringList(_historyKey) ?? ['10.0.2.2', '192.168.43.1'];
  }
}

// Global provider for shared preferences initialization
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize sharedPreferencesProvider in main.dart');
});

final networkConfigProvider = StateNotifierProvider<NetworkConfigNotifier, NetworkConfigData>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return NetworkConfigNotifier(prefs);
});
