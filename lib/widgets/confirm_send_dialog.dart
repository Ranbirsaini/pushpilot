import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class ConfirmSendDialog extends StatelessWidget {
  final int tokenCount;
  final String sampleToken;
  final String title;
  final String body;
  final String? imageUrl;
  final String projectId;
  final VoidCallback onConfirm;

  const ConfirmSendDialog({
    super.key,
    required this.tokenCount,
    required this.sampleToken,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.projectId,
    required this.onConfirm,
  });

  static Future<bool?> show(
    BuildContext context, {
    required int tokenCount,
    required String sampleToken,
    required String title,
    required String body,
    String? imageUrl,
    required String projectId,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmSendDialog(
        tokenCount: tokenCount,
        sampleToken: sampleToken,
        title: title,
        body: body,
        imageUrl: imageUrl,
        projectId: projectId,
        onConfirm: () => Navigator.of(ctx).pop(true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMultiple = tokenCount > 1;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppConstants.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.send_rounded, color: AppConstants.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            isMultiple ? 'Confirm Multicast Send' : 'Confirm Notification Dispatch',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMultiple)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppConstants.warningBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppConstants.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppConstants.warning, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You are about to dispatch this notification to $tokenCount distinct devices.',
                        style: const TextStyle(
                          color: AppConstants.warning,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Metadata card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Firebase Project', projectId),
                  const Divider(height: 16),
                  _buildDetailRow('Target Devices', '$tokenCount device(s)'),
                  const Divider(height: 16),
                  _buildDetailRow('Sample Token', AppFormatters.maskToken(sampleToken)),
                  const Divider(height: 16),
                  _buildDetailRow('Title', title, isBold: true),
                  const Divider(height: 16),
                  _buildDetailRow('Body', body),
                  if (imageUrl != null && imageUrl!.isNotEmpty) ...[
                    const Divider(height: 16),
                    _buildDetailRow('Image URL', imageUrl!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Note: This triggers Firebase Admin SDK FCM HTTP v1 dispatch.',
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: onConfirm,
          icon: const Icon(Icons.rocket_launch_rounded, size: 16),
          label: Text('Send to $tokenCount device${isMultiple ? 's' : ''}'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF94A3B8),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
