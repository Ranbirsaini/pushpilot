import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../widgets/status_badge.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _apiUrlController = TextEditingController();
  bool _isTestingApi = false;
  String? _apiTestResult;
  bool _apiTestSuccess = false;

  @override
  void initState() {
    super.initState();
    _apiUrlController.text = StorageService.getApiBaseUrl();
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    super.dispose();
  }

  Future<void> _testApiConnection() async {
    setState(() {
      _isTestingApi = true;
      _apiTestResult = null;
    });

    final stopwatch = Stopwatch()..start();
    final res = await ApiService.checkHealth();
    stopwatch.stop();

    setState(() {
      _isTestingApi = false;
      _apiTestSuccess = res.success;
      if (res.success) {
        _apiTestResult =
            '✅ Server is online! (Latency: ${stopwatch.elapsedMilliseconds}ms, Version: ${res.data?['version'] ?? "1.0.0"})';
      } else {
        _apiTestResult = '❌ Cannot connect: ${res.errorMessage}';
      }
    });

    if (mounted) {
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      projectProvider.checkBackendHealth();
    }
  }

  Future<void> _saveApiUrl() async {
    final url = _apiUrlController.text.trim();
    if (url.isNotEmpty) {
      await StorageService.setApiBaseUrl(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API Base URL saved successfully!'),
            backgroundColor: AppConstants.success,
          ),
        );
        _testApiConnection();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final projectProvider = Provider.of<ProjectProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Settings & Configuration',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Configure your backend server endpoint, theme preferences, and system diagnostics',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 24),

          // Backend API Configuration Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.dns_rounded, color: AppConstants.primary, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Backend Server Endpoint',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      StatusBadge(
                        label: projectProvider.isBackendOnline ? 'Online' : 'Offline',
                        color: projectProvider.isBackendOnline ? AppConstants.success : AppConstants.error,
                        icon: projectProvider.isBackendOnline ? Icons.check_circle : Icons.error_outline,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'PushPilot Flutter Web communicates with the Node.js Express backend to execute Firebase Admin SDK calls securely without exposing private keys to the browser.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _apiUrlController,
                          decoration: const InputDecoration(
                            labelText: 'API Base URL',
                            hintText: 'http://localhost:5050/api',
                            prefixIcon: Icon(Icons.link_rounded, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _saveApiUrl,
                        icon: const Icon(Icons.save_rounded, size: 18),
                        label: const Text('Save URL'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _isTestingApi ? null : _testApiConnection,
                        icon: _isTestingApi
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.network_ping_rounded, size: 18),
                        label: const Text('Test Ping'),
                      ),
                    ],
                  ),
                  if (_apiTestResult != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _apiTestSuccess ? AppConstants.successBg : AppConstants.errorBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (_apiTestSuccess ? AppConstants.success : AppConstants.error)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _apiTestResult!,
                        style: TextStyle(
                          color: _apiTestSuccess ? AppConstants.success : AppConstants.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Theme Preferences Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.palette_rounded, color: AppConstants.primary, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Appearance & Theme',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.dark,
                    groupValue: themeProvider.themeMode,
                    title: const Text('Dark Mode (Recommended)'),
                    subtitle: const Text('Sleek dark theme optimized for SaaS dashboard productivity'),
                    secondary: const Icon(Icons.dark_mode_rounded),
                    onChanged: (val) {
                      if (val != null) themeProvider.setThemeMode(val);
                    },
                  ),
                  const Divider(),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.light,
                    groupValue: themeProvider.themeMode,
                    title: const Text('Light Mode'),
                    subtitle: const Text('Clean modern light layout with high contrast'),
                    secondary: const Icon(Icons.light_mode_rounded),
                    onChanged: (val) {
                      if (val != null) themeProvider.setThemeMode(val);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // FCM HTTP v1 Standards Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: AppConstants.success, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'FCM HTTP v1 Standard Compliance',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'PushPilot complies fully with Google\'s latest FCM HTTP v1 API. The legacy FCM HTTP APIs (using server keys) were deprecated and shut down by Google in June 2024. FCM v1 uses short-lived OAuth 2.0 access tokens generated via service accounts for maximum security.',
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
