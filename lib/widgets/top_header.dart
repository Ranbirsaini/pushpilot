import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';
import 'status_badge.dart';

class TopHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onQuickTestPressed;

  const TopHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onMenuPressed,
    this.onQuickTestPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final projectProvider = Provider.of<ProjectProvider>(context);

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF0D1424)
            : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (onMenuPressed != null) ...[
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: onMenuPressed,
              tooltip: 'Toggle Menu',
            ),
            const SizedBox(width: 8),
          ],
          // App Logo Icon
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/images/app_logo.png',
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppConstants.primary, AppConstants.secondary],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Title & Subtitle
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
              ],
            ),
          ),

          // Backend Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: projectProvider.isBackendOnline
                  ? AppConstants.successBg
                  : AppConstants.errorBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: projectProvider.isBackendOnline
                    ? AppConstants.success.withValues(alpha: 0.3)
                    : AppConstants.error.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: projectProvider.isBackendOnline
                        ? AppConstants.success
                        : AppConstants.error,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  projectProvider.isBackendOnline ? 'Backend Online' : 'Backend Offline',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: projectProvider.isBackendOnline
                        ? AppConstants.success
                        : AppConstants.error,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Active Firebase Project Badge
          if (projectProvider.isConnected) ...[
            StatusBadge.success(
              label: projectProvider.session!.projectId,
              icon: Icons.check_circle_rounded,
            ),
            const SizedBox(width: 12),
          ],

          // Quick Test Notification Button
          if (onQuickTestPressed != null && projectProvider.isConnected) ...[
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onPressed: onQuickTestPressed,
              icon: const Icon(Icons.bolt_rounded, size: 16),
              label: const Text('Quick Test', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 12),
          ],

          // Dark/Light Theme Toggle
          IconButton(
            onPressed: () => themeProvider.toggleTheme(),
            icon: Icon(
              themeProvider.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              size: 20,
            ),
            tooltip: themeProvider.isDarkMode ? 'Switch to Light Theme' : 'Switch to Dark Theme',
          ),
        ],
      ),
    );
  }
}
