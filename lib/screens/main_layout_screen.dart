import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../providers/project_provider.dart';
import '../utils/constants.dart';
import '../widgets/sidebar_nav.dart';
import '../widgets/top_header.dart';
import 'dashboard_screen.dart';
import 'composer_screen.dart';
import 'credentials_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<String> _pageTitles = [
    'Dashboard',
    'Notification Composer',
    'Service Account Credentials',
    'Delivery History',
    'Settings & API',
  ];

  final List<String> _pageSubtitles = [
    'Overview of FCM request volume and system metrics',
    'Build and preview push notifications for Android and iOS',
    'Connect and manage Firebase Admin SDK service account credentials',
    'Detailed log of dispatched notifications and per-token acceptance',
    'Backend API configuration and system preferences',
  ];

  void _onNavigate(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  void _showQuickTestDialog(BuildContext context) {
    final tokenController = TextEditingController();
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    final notifProvider = Provider.of<NotificationProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.bolt_rounded, color: AppConstants.warning),
            SizedBox(width: 10),
            Text('Quick Test FCM Notification'),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter a single device registration token to immediately send a test ping from your connected Firebase project.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tokenController,
                maxLines: 2,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: InputDecoration(
                  labelText: 'FCM Device Token',
                  hintText: 'Paste FCM token from Flutter/Android/iOS device...',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.flash_on_rounded),
                    tooltip: 'Insert dummy token',
                    onPressed: () {
                      tokenController.text =
                          'fQ91zklA9482710492817409182374981723984712093847109283740981724';
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final token = tokenController.text.trim();
              if (token.isEmpty) return;
              Navigator.of(ctx).pop();

              final success = await notifProvider.sendQuickTest(
                token: token,
                projectProvider: projectProvider,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? '✅ Test notification accepted by FCM HTTP v1!'
                          : '❌ Failed: ${notifProvider.sendError}',
                    ),
                    backgroundColor: success ? AppConstants.success : AppConstants.error,
                  ),
                );
              }
            },
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Send Test Ping'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        final screens = [
          DashboardScreen(onNavigate: _onNavigate),
          ComposerScreen(onNavigate: _onNavigate),
          CredentialsScreen(onNavigate: _onNavigate),
          HistoryScreen(onNavigate: _onNavigate),
          const SettingsScreen(),
        ];

        return Scaffold(
          key: _scaffoldKey,
          drawer: isDesktop
              ? null
              : Drawer(
                  child: SidebarNav(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _onNavigate,
                  ),
                ),
          body: Row(
            children: [
              if (isDesktop)
                SidebarNav(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onNavigate,
                ),
              Expanded(
                child: Column(
                  children: [
                    TopHeader(
                      title: _pageTitles[_selectedIndex],
                      subtitle: _pageSubtitles[_selectedIndex],
                      onMenuPressed: isDesktop
                          ? null
                          : () => _scaffoldKey.currentState?.openDrawer(),
                      onQuickTestPressed: () => _showQuickTestDialog(context),
                    ),
                    Expanded(
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: screens,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
