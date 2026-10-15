import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../utils/constants.dart';

class JsonEditorWidget extends StatefulWidget {
  const JsonEditorWidget({super.key});

  @override
  State<JsonEditorWidget> createState() => _JsonEditorWidgetState();
}

class _JsonEditorWidgetState extends State<JsonEditorWidget> {
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _valController = TextEditingController();
  late TextEditingController _rawTextController;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    _rawTextController = TextEditingController(text: provider.rawJsonData);
  }

  @override
  void dispose() {
    _keyController.dispose();
    _valController.dispose();
    _rawTextController.dispose();
    super.dispose();
  }

  void _addPair(NotificationProvider provider) {
    if (_keyController.text.trim().isNotEmpty) {
      provider.addCustomDataPair(_keyController.text, _valController.text);
      _keyController.clear();
      _valController.clear();
      _rawTextController.text = provider.rawJsonData;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<NotificationProvider>(context);

    // Keep raw text controller in sync if not in raw mode
    if (!provider.isRawJsonMode && _rawTextController.text != provider.rawJsonData) {
      _rawTextController.text = provider.rawJsonData;
    }

    return Card(
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
                    const Icon(Icons.data_object_rounded, size: 20, color: AppConstants.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Custom Key-Value Data (FCM data)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Toggle Mode (Form vs Raw JSON)
                Container(
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildModeTab(
                        title: 'Visual Fields',
                        icon: Icons.list_alt_rounded,
                        isSelected: !provider.isRawJsonMode,
                        onTap: () => provider.toggleJsonMode(false),
                      ),
                      _buildModeTab(
                        title: 'Raw JSON',
                        icon: Icons.code_rounded,
                        isSelected: provider.isRawJsonMode,
                        onTap: () => provider.toggleJsonMode(true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Optional custom data payload attached to the notification for in-app navigation or custom handling.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),

            if (provider.isRawJsonMode) ...[
              // Raw JSON Editor
              TextField(
                controller: _rawTextController,
                maxLines: 8,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  hintText: '{\n  "screen": "product_details",\n  "productId": "123"\n}',
                  fillColor: theme.brightness == Brightness.dark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (val) {
                  provider.updateRawJson(val);
                },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (provider.jsonValidationError != null)
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, size: 16, color: AppConstants.error),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              provider.jsonValidationError!,
                              style: const TextStyle(color: AppConstants.error, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const Row(
                      children: [
                        Icon(Icons.check_circle_outline, size: 16, color: AppConstants.success),
                        SizedBox(width: 6),
                        Text(
                          'Valid JSON syntax',
                          style: TextStyle(color: AppConstants.success, fontSize: 12),
                        ),
                      ],
                    ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _rawTextController.text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('JSON payload copied to clipboard!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Copy JSON', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ] else ...[
              // Visual Key-Value Editor
              if (provider.customData.isNotEmpty) ...[
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.customData.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final key = provider.customData.keys.elementAt(idx);
                      final value = provider.customData[key];

                      return ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppConstants.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: AppConstants.primaryLight,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(':', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                value ?? '',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: theme.textTheme.bodyMedium?.color,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppConstants.error),
                          onPressed: () {
                            provider.removeCustomDataPair(key);
                            _rawTextController.text = provider.rawJsonData;
                          },
                          tooltip: 'Delete parameter',
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Add Key-Value Row Form
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 4,
                    child: TextField(
                      controller: _keyController,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Key (e.g. screen)',
                        hintText: 'e.g. action',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 5,
                    child: TextField(
                      controller: _valController,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Value (e.g. cart)',
                        hintText: 'e.g. order_123',
                        isDense: true,
                      ),
                      onSubmitted: (_) => _addPair(provider),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    onPressed: () => _addPair(provider),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : AppConstants.darkTextSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : AppConstants.darkTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
