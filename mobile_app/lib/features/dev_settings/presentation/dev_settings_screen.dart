import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/network_config.dart';
import '../../../core/theme/app_theme.dart';

class DevSettingsScreen extends ConsumerStatefulWidget {
  const DevSettingsScreen({super.key});

  @override
  ConsumerState<DevSettingsScreen> createState() => _DevSettingsScreenState();
}

class _DevSettingsScreenState extends ConsumerState<DevSettingsScreen> {
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  
  bool _testingConnection = false;
  String? _testResult;
  bool _testSuccess = false;

  final _formKey = GlobalKey<FormState>();

  // Simple IPv4 / Hostname regex validation
  final _ipRegex = RegExp(r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$|^localhost$');

  @override
  void initState() {
    super.initState();
    final currentConfig = ref.read(networkConfigProvider);
    _hostController = TextEditingController(text: currentConfig.host);
    _portController = TextEditingController(text: currentConfig.port);
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _testingConnection = true;
      _testResult = null;
    });

    final testHost = _hostController.text.trim();
    final testPort = _portController.text.trim();
    final testUrl = 'http://$testHost:$testPort/api/products';

    try {
      final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 4)));
      final response = await dio.get(testUrl);
      
      setState(() {
        _testSuccess = response.statusCode == 200;
        _testResult = _testSuccess 
            ? 'Connection Successful! Reachable.' 
            : 'Error: Received status ${response.statusCode}';
      });
    } catch (e) {
      setState(() {
        _testSuccess = false;
        _testResult = 'Connection Failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _testingConnection = false;
      });
    }
  }

  void _saveConfig() {
    if (!_formKey.currentState!.validate()) return;
    
    final host = _hostController.text.trim();
    final port = _portController.text.trim();
    
    ref.read(networkConfigProvider.notifier).updateConfig(host, port);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Development API settings saved successfully!'),
        backgroundColor: AppColors.emeraldGreen,
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(networkConfigProvider.notifier);
    final history = notifier.getHostHistory();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dev Server Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.flipkartBlue),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Configure the API gateway IP to connect your phone to the backend. The laptop must be on the same WiFi/hotspot subnet.',
                          style: TextStyle(fontSize: 12, color: AppColors.textDark),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _hostController,
                decoration: const InputDecoration(
                  labelText: 'Server Host / IP Address',
                  hintText: 'e.g. 192.168.43.1',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Host is required';
                  if (!_ipRegex.hasMatch(val.trim())) return 'Enter a valid IPv4 address or "localhost"';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _portController,
                decoration: const InputDecoration(
                  labelText: 'Gateway Port',
                  hintText: '8080',
                ),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Port is required';
                  final port = int.tryParse(val.trim());
                  if (port == null || port <= 0 || port > 65535) return 'Enter a valid port number';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Host History Chips
              const Text(
                'Quick Select Previous Hosts:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textLight),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: history.map((host) {
                  return ChoiceChip(
                    label: Text(host, style: const TextStyle(fontSize: 12)),
                    selected: _hostController.text == host,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _hostController.text = host;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _testingConnection ? null : _testConnection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkNavy,
                  foregroundColor: Colors.white,
                ),
                child: _testingConnection
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('TEST CONNECTION'),
              ),
              const SizedBox(height: 12),

              if (_testResult != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _testSuccess ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _testSuccess ? Colors.green.shade200 : Colors.red.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _testSuccess ? Icons.check_circle : Icons.error,
                        color: _testSuccess ? AppColors.emeraldGreen : AppColors.errorRed,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _testResult!,
                          style: TextStyle(
                            fontSize: 12,
                            color: _testSuccess ? Colors.green.shade900 : Colors.red.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _saveConfig,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.flipkartYellow,
                  foregroundColor: AppColors.flipkartBlue,
                ),
                child: const Text('SAVE SETTINGS', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
