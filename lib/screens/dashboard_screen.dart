import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../providers/project_provider.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/stats_card.dart';
import '../widgets/status_badge.dart';

class DashboardScreen extends StatelessWidget {
  final ValueChanged<int> onNavigate;

  const DashboardScreen({super.key, required this.onNavigate});

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
    final theme = Theme.of(context);
    final notifProvider = Provider.of<NotificationProvider>(context);
    final projectProvider = Provider.of<ProjectProvider>(context);

    final totalReqs = notifProvider.totalRequests;
    final successCount = notifProvider.successfulDeliveries;
    final failureCount = notifProvider.failedDeliveries;
    final rate = notifProvider.successRate.toStringAsFixed(1);
    final recentHistory = notifProvider.history.take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner if not connected
          if (!projectProvider.isConnected)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.primary.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.key_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Connect your Firebase Service Account',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Upload your project service account JSON to start sending push notifications directly via FCM HTTP v1.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppConstants.primaryDark,
                    ),
                    onPressed: () => onNavigate(2), // Navigate to Credentials tab
                    icon: const Icon(Icons.upload_file_rounded, size: 18),
                    label: const Text('Upload JSON'),
                  ),
                ],
              ),
            ),

          // Overview Title & Quick Actions
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard Overview',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Live metrics and delivery status for Firebase Cloud Messaging',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (projectProvider.isConnected)
                    ElevatedButton.icon(
                      onPressed: () => _showQuickTestDialog(context),
                      icon: const Icon(Icons.bolt_rounded, size: 18),
                      label: const Text('Quick Test'),
                    ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.secondary,
                    ),
                    onPressed: () => onNavigate(1), // Go to Composer
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Compose New'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Metrics Grid (Responsive Layout)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              final crossAxisCount = isWide ? 4 : 2;
              final itemWidth = (constraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount;
              final childAspectRatio = (itemWidth / 165).clamp(0.8, 2.5);

              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: childAspectRatio,
                children: [
                  StatsCard(
                    title: 'Total Requests',
                    value: AppFormatters.formatNumber(totalReqs),
                    subtitle: '${notifProvider.totalTokensSent} tokens targeted',
                    icon: Icons.send_rounded,
                    accentColor: AppConstants.primary,
                  ),
                  StatsCard(
                    title: 'FCM Accepted',
                    value: AppFormatters.formatNumber(successCount),
                    subtitle: '$rate% acceptance rate',
                    icon: Icons.check_circle_rounded,
                    accentColor: AppConstants.success,
                  ),
                  StatsCard(
                    title: 'Failed Requests',
                    value: AppFormatters.formatNumber(failureCount),
                    subtitle: failureCount == 0 ? 'Zero errors' : 'Check history for details',
                    icon: Icons.cancel_rounded,
                    accentColor: AppConstants.error,
                  ),
                  StatsCard(
                    title: 'Firebase Project',
                    value: projectProvider.isConnected
                        ? projectProvider.session!.projectId
                        : 'Offline',
                    subtitle: projectProvider.isConnected ? 'Active & Ready' : 'Upload credentials',
                    icon: Icons.cloud_rounded,
                    accentColor: AppConstants.secondary,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),

          // Recent Activity Table
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.history_rounded, size: 20, color: AppConstants.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Recent Delivery Activity',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () => onNavigate(3), // Go to History screen
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: const Text('View Full History'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (recentHistory.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 48,
                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No notifications dispatched yet',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Send your first push notification from the composer tab to view delivery activity.',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => onNavigate(1),
                            icon: const Icon(Icons.send_rounded, size: 16),
                            label: const Text('Send Notification Now'),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recentHistory.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final item = recentHistory[idx];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: item.status == 'SUCCESS'
                                  ? AppConstants.successBg
                                  : item.status == 'FAILED'
                                      ? AppConstants.errorBg
                                      : AppConstants.warningBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              item.status == 'SUCCESS'
                                  ? Icons.check_circle_outline_rounded
                                  : item.status == 'FAILED'
                                      ? Icons.error_outline_rounded
                                      : Icons.warning_amber_rounded,
                              color: item.status == 'SUCCESS'
                                  ? AppConstants.success
                                  : item.status == 'FAILED'
                                      ? AppConstants.error
                                      : AppConstants.warning,
                              size: 20,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusBadge(
                                label: item.status,
                                color: item.status == 'SUCCESS'
                                    ? AppConstants.success
                                    : item.status == 'FAILED'
                                        ? AppConstants.error
                                        : AppConstants.warning,
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                item.body,
                                style: theme.textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'Target: ${AppFormatters.maskToken(item.sampleToken)}',
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (item.tokensCount > 1)
                                    Text(
                                      ' (+${item.tokensCount - 1} more)',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '• ${AppFormatters.formatTimestamp(item.timestamp)}',
                                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
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
