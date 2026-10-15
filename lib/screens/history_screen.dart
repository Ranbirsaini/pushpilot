import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/notification_history_item.dart';
import '../providers/notification_provider.dart';
import '../providers/project_provider.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/status_badge.dart';

class HistoryScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigate;

  const HistoryScreen({super.key, this.onNavigate});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filterStatus = 'ALL'; // 'ALL', 'SUCCESS', 'FAILED', 'PARTIAL'
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showErrorDetailsDialog(BuildContext context, NotificationHistoryItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppConstants.error),
            const SizedBox(width: 10),
            Text('Delivery Details: ${item.title}'),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoRow('Timestamp', AppFormatters.formatTimestamp(item.timestamp)),
                _buildInfoRow('Project ID', item.projectId),
                _buildInfoRow('Target Count', '${item.tokensCount} device token(s)'),
                _buildInfoRow('Sample Token', AppFormatters.maskToken(item.sampleToken)),
                _buildInfoRow('Success Count', item.successCount.toString()),
                _buildInfoRow('Failure Count', item.failureCount.toString()),
                const SizedBox(height: 16),
                const Text('Per-Token Responses:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                if (item.results.isEmpty)
                  const Text('No detailed results recorded.', style: TextStyle(fontSize: 12))
                else
                  ...item.results.map((r) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: r.success ? AppConstants.successBg : AppConstants.errorBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (r.success ? AppConstants.success : AppConstants.error)
                                .withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  r.success ? Icons.check_circle : Icons.error,
                                  size: 16,
                                  color: r.success ? AppConstants.success : AppConstants.error,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  r.token,
                                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                                ),
                              ],
                            ),
                            if (r.messageId != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Message ID: ${r.messageId}',
                                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                              ),
                            ],
                            if (r.error != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Error Code: ${r.error!.code}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.error,
                                ),
                              ),
                              Text(
                                r.error!.message,
                                style: const TextStyle(fontSize: 11, color: AppConstants.error),
                              ),
                              if (r.error!.action != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Fix: ${r.error!.action}',
                                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ],
                          ],
                        ),
                      )),
                if (item.data.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Custom Payload (data):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      const JsonEncoder.withIndent('  ').convert(item.data),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
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

    final rawHistory = notifProvider.history;
    final searchTerm = _searchController.text.trim().toLowerCase();

    // Filtered items
    final filteredHistory = rawHistory.where((item) {
      if (_filterStatus != 'ALL' && item.status != _filterStatus) {
        return false;
      }
      if (searchTerm.isNotEmpty) {
        final matchesTitle = item.title.toLowerCase().contains(searchTerm);
        final matchesBody = item.body.toLowerCase().contains(searchTerm);
        final matchesProject = item.projectId.toLowerCase().contains(searchTerm);
        final matchesToken = item.sampleToken.toLowerCase().contains(searchTerm);
        if (!matchesTitle && !matchesBody && !matchesProject && !matchesToken) {
          return false;
        }
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notification History',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Complete audit log of dispatched push notifications with FCM HTTP v1 acceptance results',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => notifProvider.syncHistoryFromBackend(
                      projectId: projectProvider.session?.projectId,
                    ),
                    icon: notifProvider.isLoadingHistory
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync_rounded, size: 16),
                    label: const Text('Refresh'),
                  ),
                  const SizedBox(width: 10),
                  if (rawHistory.isNotEmpty)
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: AppConstants.error),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Clear Notification History?'),
                            content: const Text(
                              'This will permanently delete local history records. This action cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppConstants.error),
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Clear All'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await notifProvider.clearHistory();
                        }
                      },
                      icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                      label: const Text('Clear History'),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Filters & Search Bar
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Search
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by title, body, token or project...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        isDense: true,
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Filter Pills
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterChip('ALL', 'All (${rawHistory.length})'),
                      _buildFilterChip('SUCCESS', 'Success'),
                      _buildFilterChip('PARTIAL', 'Partial'),
                      _buildFilterChip('FAILED', 'Failed'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // History List
          if (filteredHistory.isEmpty)
            Card(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(
                      Icons.history_toggle_off_rounded,
                      size: 56,
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      rawHistory.isEmpty
                          ? 'No notification history yet'
                          : 'No notifications match your search/filter criteria',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      rawHistory.isEmpty
                          ? 'Notifications sent from the composer will be recorded here.'
                          : 'Try adjusting your search terms or filter selection.',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (rawHistory.isEmpty) ...[
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => widget.onNavigate?.call(1),
                        icon: const Icon(Icons.send_rounded, size: 16),
                        label: const Text('Send Your First Notification'),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredHistory.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final item = filteredHistory[idx];
                final isSuccess = item.status == 'SUCCESS';
                final isFailed = item.status == 'FAILED';

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSuccess
                                    ? AppConstants.successBg
                                    : isFailed
                                        ? AppConstants.errorBg
                                        : AppConstants.warningBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isSuccess
                                    ? Icons.check_circle_rounded
                                    : isFailed
                                        ? Icons.cancel_rounded
                                        : Icons.warning_rounded,
                                color: isSuccess
                                    ? AppConstants.success
                                    : isFailed
                                        ? AppConstants.error
                                        : AppConstants.warning,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      StatusBadge(
                                        label: item.status,
                                        color: isSuccess
                                            ? AppConstants.success
                                            : isFailed
                                                ? AppConstants.error
                                                : AppConstants.warning,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.body,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 16,
                                    runSpacing: 6,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.devices_rounded, size: 14, color: AppConstants.primaryLight),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Token: ${AppFormatters.maskToken(item.sampleToken)}',
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
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.cloud_rounded, size: 14, color: Color(0xFF94A3B8)),
                                          const SizedBox(width: 4),
                                          Text(
                                            item.projectId,
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF94A3B8)),
                                          const SizedBox(width: 4),
                                          Text(
                                            AppFormatters.formatTimestamp(item.timestamp),
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'Accepted: ${item.successCount} / ${item.tokensCount}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isSuccess ? AppConstants.success : AppConstants.warning,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: item.sampleToken));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Device token copied!'), duration: Duration(seconds: 1)),
                                );
                              },
                              icon: const Icon(Icons.copy_rounded, size: 14),
                              label: const Text('Copy Token', style: TextStyle(fontSize: 11)),
                            ),
                            if (item.data.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              TextButton.icon(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: jsonEncode(item.data)));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Custom data copied!'), duration: Duration(seconds: 1)),
                                  );
                                },
                                icon: const Icon(Icons.code_rounded, size: 14),
                                label: const Text('Copy Data JSON', style: TextStyle(fontSize: 11)),
                              ),
                            ],
                            const SizedBox(width: 6),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onPressed: () => _showErrorDetailsDialog(context, item),
                              icon: const Icon(Icons.visibility_rounded, size: 14),
                              label: const Text('View Response Details', style: TextStyle(fontSize: 11)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filterStatus == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _filterStatus = value;
        });
      },
    );
  }
}
