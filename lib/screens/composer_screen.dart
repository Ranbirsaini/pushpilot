import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/send_result.dart';
import '../providers/notification_provider.dart';
import '../providers/project_provider.dart';
import '../utils/constants.dart';
import '../widgets/confirm_send_dialog.dart';
import '../widgets/json_editor_widget.dart';
import '../widgets/mobile_notification_preview.dart';

class ComposerScreen extends StatelessWidget {
  final ValueChanged<int>? onNavigate;

  const ComposerScreen({super.key, this.onNavigate});

  Future<void> _handleSend(BuildContext context) async {
    final notifProvider = Provider.of<NotificationProvider>(context, listen: false);
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);

    // Check project connection
    if (!projectProvider.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please connect your Firebase Service Account first!'),
          backgroundColor: AppConstants.warning,
          action: SnackBarAction(
            label: 'Go to Credentials',
            textColor: Colors.white,
            onPressed: () => onNavigate?.call(2),
          ),
        ),
      );
      return;
    }

    final tokens = notifProvider.parsedTokens;
    if (tokens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one FCM device token.'),
          backgroundColor: AppConstants.error,
        ),
      );
      return;
    }

    if (notifProvider.titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification title is required.'),
          backgroundColor: AppConstants.error,
        ),
      );
      return;
    }

    if (notifProvider.bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification body message is required.'),
          backgroundColor: AppConstants.error,
        ),
      );
      return;
    }

    // Confirmation dialog before sending (especially for multiple tokens)
    final confirmed = await ConfirmSendDialog.show(
      context,
      tokenCount: tokens.length,
      sampleToken: tokens.first,
      title: notifProvider.titleController.text.trim(),
      body: notifProvider.bodyController.text.trim(),
      imageUrl: notifProvider.imageUrlController.text.trim(),
      projectId: projectProvider.session?.projectId ?? 'N/A',
    );

    if (confirmed == true && context.mounted) {
      final success = await notifProvider.sendNotification(projectProvider);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🎉 Successfully accepted by FCM HTTP v1 for ${notifProvider.lastSendResult?.successCount} device(s)!',
              ),
              backgroundColor: AppConstants.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Send Failed: ${notifProvider.sendError}'),
              backgroundColor: AppConstants.error,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifProvider = Provider.of<NotificationProvider>(context);
    final projectProvider = Provider.of<ProjectProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notification Composer',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Compose, preview, and dispatch push notifications via Firebase Admin SDK',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => notifProvider.loadSamplePayload(),
                    icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                    label: const Text('Load Sample Data'),
                  ),
                  const SizedBox(width: 10),
                  TextButton.icon(
                    onPressed: () => notifProvider.clearForm(),
                    icon: const Icon(Icons.clear_all_rounded, size: 18),
                    label: const Text('Clear Form'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Last Send Result Banner (if exists)
          if (notifProvider.lastSendResult != null) ...[
            _buildResultBanner(context, notifProvider.lastSendResult!),
            const SizedBox(height: 20),
          ],

          // Error Banner (if any)
          if (notifProvider.sendError != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.errorBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppConstants.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppConstants.error, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dispatch Error',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: AppConstants.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        SelectableText(
                          notifProvider.sendError!,
                          style: const TextStyle(color: AppConstants.error, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Main Responsive Grid: Form on Left, Live Preview on Right
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 960;

              final formColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Device Tokens Card
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
                                  const Icon(Icons.devices_rounded, size: 20, color: AppConstants.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Target Device FCM Token(s)',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppConstants.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  '${notifProvider.tokenCount} Token(s) Detected',
                                  style: const TextStyle(
                                    color: AppConstants.primaryLight,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter one FCM token per line to send to multiple devices simultaneously, or paste a single token.',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: notifProvider.tokensController,
                            maxLines: 4,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              height: 1.4,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'fQ91zklA9482710492817409182374981723984712093847109283740981724\nc7F819401827391028371928371928371928371928371928371928371928371',
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.content_paste_rounded, size: 18),
                                tooltip: 'Paste from clipboard',
                                onPressed: () async {
                                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                                  if (data?.text != null) {
                                    notifProvider.tokensController.text = data!.text!;
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section 2: Notification Content Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.edit_note_rounded, size: 22, color: AppConstants.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Notification Content',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Title
                          TextField(
                            controller: notifProvider.titleController,
                            decoration: const InputDecoration(
                              labelText: 'Notification Title *',
                              hintText: 'e.g. 🎉 Special Weekend Offer!',
                              prefixIcon: Icon(Icons.title_rounded, size: 20),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Body
                          TextField(
                            controller: notifProvider.bodyController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Notification Message Body *',
                              hintText: 'e.g. Tap here to unlock 50% discount on all trending items!',
                              prefixIcon: Icon(Icons.message_rounded, size: 20),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Image URL
                          TextField(
                            controller: notifProvider.imageUrlController,
                            decoration: const InputDecoration(
                              labelText: 'Image URL (Optional)',
                              hintText: 'https://example.com/images/promo.png',
                              prefixIcon: Icon(Icons.image_outlined, size: 20),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Priority Selector
                          Row(
                            children: [
                              const Text(
                                'FCM Priority:',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              const SizedBox(width: 14),
                              ChoiceChip(
                                label: const Text('High Priority'),
                                selected: notifProvider.priority == 'high',
                                onSelected: (_) => notifProvider.setPriority('high'),
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text('Normal'),
                                selected: notifProvider.priority == 'normal',
                                onSelected: (_) => notifProvider.setPriority('normal'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section 3: Custom Data JSON Editor
                  const JsonEditorWidget(),
                  const SizedBox(height: 24),

                  // Section 4: Send Notification Action Bar
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? const Color(0xFF151D2F)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ready to dispatch?',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              projectProvider.isConnected
                                  ? 'Connected to ${projectProvider.session!.projectId}'
                                  : 'Firebase project not connected',
                              style: TextStyle(
                                fontSize: 12,
                                color: projectProvider.isConnected
                                    ? AppConstants.success
                                    : AppConstants.warning,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                            elevation: 4,
                          ),
                          onPressed: notifProvider.isSending
                              ? null
                              : () => _handleSend(context),
                          icon: notifProvider.isSending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.rocket_launch_rounded, size: 20),
                          label: Text(
                            notifProvider.isSending
                                ? 'Dispatching...'
                                : 'Send Notification (${notifProvider.tokenCount})',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final previewColumn = MobileNotificationPreview(
                title: notifProvider.titleController.text,
                body: notifProvider.bodyController.text,
                imageUrl: notifProvider.imageUrlController.text,
                platform: notifProvider.previewPlatform,
                onPlatformChanged: (p) => notifProvider.setPreviewPlatform(p),
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: formColumn),
                    const SizedBox(width: 24),
                    Expanded(flex: 4, child: previewColumn),
                  ],
                );
              } else {
                return Column(
                  children: [
                    previewColumn,
                    const SizedBox(height: 24),
                    formColumn,
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultBanner(BuildContext context, SendResult result) {
    final theme = Theme.of(context);
    final isSuccess = result.failureCount == 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isSuccess ? AppConstants.successBg : AppConstants.warningBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isSuccess ? AppConstants.success : AppConstants.warning).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle_rounded : Icons.info_rounded,
                color: isSuccess ? AppConstants.success : AppConstants.warning,
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSuccess
                          ? 'FCM HTTP v1 Acceptance Succeeded!'
                          : 'Partial Notification Delivery Results',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSuccess ? AppConstants.success : AppConstants.warning,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Successfully accepted: ${result.successCount} of ${result.totalTokens} token(s). Failed: ${result.failureCount}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (result.results.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Per-Token Details:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: result.results.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, idx) {
                final item = result.results[idx];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.success ? Icons.check_circle : Icons.error,
                        size: 16,
                        color: item.success ? AppConstants.success : AppConstants.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.token,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.success
                              ? 'Message ID: ${item.messageId ?? "Accepted"}'
                              : 'Error: ${item.error?.message ?? "Delivery rejected"}',
                          style: TextStyle(
                            fontSize: 11,
                            color: item.success ? AppConstants.success : AppConstants.error,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          if (result.note != null) ...[
            const SizedBox(height: 12),
            Text(
              'ℹ️ ${result.note}',
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }
}
