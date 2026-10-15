import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/project_provider.dart';
import '../utils/constants.dart';
import 'status_badge.dart';

class DragDropUploadWidget extends StatefulWidget {
  final VoidCallback? onConnectedSuccess;

  const DragDropUploadWidget({super.key, this.onConnectedSuccess});

  @override
  State<DragDropUploadWidget> createState() => _DragDropUploadWidgetState();
}

class _DragDropUploadWidgetState extends State<DragDropUploadWidget> {
  bool _isDragging = false;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        String? jsonString;

        if (file.bytes != null) {
          jsonString = utf8.decode(file.bytes!);
        }

        if (jsonString != null) {
          if (!mounted) return;
          final provider = Provider.of<ProjectProvider>(context, listen: false);
          final success = await provider.connectWithJson(jsonString, fileName: file.name);
          if (success && widget.onConnectedSuccess != null) {
            widget.onConnectedSuccess!();
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error reading file: $e'),
          backgroundColor: AppConstants.error,
        ),
      );
    }
  }

  Future<void> _handleDroppedFiles(List<dynamic> files) async {
    if (files.isEmpty) return;
    try {
      final file = files.first;
      final bytes = await file.readAsBytes();
      final jsonString = utf8.decode(bytes);

      if (!mounted) return;
      final provider = Provider.of<ProjectProvider>(context, listen: false);
      final success = await provider.connectWithJson(jsonString, fileName: file.name);
      if (success && widget.onConnectedSuccess != null) {
        widget.onConnectedSuccess!();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to read dropped file: $e'),
          backgroundColor: AppConstants.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final projectProvider = Provider.of<ProjectProvider>(context);
    final isConnected = projectProvider.isConnected;
    final isConnecting = projectProvider.isConnecting;
    final session = projectProvider.session;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Firebase Service Account',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upload your private key JSON to authenticate with Firebase Cloud Messaging HTTP v1',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                if (isConnected)
                  StatusBadge.success(
                    label: 'Connected: ${session?.projectId}',
                    icon: Icons.cloud_done_rounded,
                  )
                else if (isConnecting)
                  StatusBadge.warning(
                    label: 'Connecting...',
                    icon: Icons.sync_rounded,
                  )
                else
                  StatusBadge.info(
                    label: 'Not Connected',
                    icon: Icons.cloud_off_rounded,
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Drop zone area
            DropTarget(
              onDragEntered: (_) => setState(() => _isDragging = true),
              onDragExited: (_) => setState(() => _isDragging = false),
              onDragDone: (detail) {
                setState(() => _isDragging = false);
                _handleDroppedFiles(detail.files);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: BoxDecoration(
                  color: _isDragging
                      ? AppConstants.primary.withValues(alpha: 0.1)
                      : isConnected
                          ? AppConstants.success.withValues(alpha: 0.05)
                          : theme.brightness == Brightness.dark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isDragging
                        ? AppConstants.primary
                        : isConnected
                            ? AppConstants.success.withValues(alpha: 0.5)
                            : theme.dividerColor,
                    width: _isDragging ? 2 : 1.5,
                    style: BorderStyle.solid,
                  ),
                ),
                child: isConnected
                    ? _buildConnectedView(context, projectProvider, session!)
                    : _buildUploadPromptView(context, isConnecting),
              ),
            ),

            // Error banner if any
            if (projectProvider.errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConstants.errorBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppConstants.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppConstants.error, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Validation / Connection Error',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppConstants.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            projectProvider.errorMessage!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppConstants.error,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: AppConstants.error),
                      onPressed: () => projectProvider.clearError(),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            // Important hint note
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: AppConstants.primaryLight),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Important: Upload the Firebase Service Account JSON (from Firebase Console > Service Accounts), NOT Android\'s google-services.json file.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadPromptView(BuildContext context, bool isConnecting) {
    final theme = Theme.of(context);

    if (isConnecting) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(strokeWidth: 3),
          SizedBox(height: 16),
          Text(
            'Validating credentials & connecting to Firebase Admin SDK...',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.cloud_upload_outlined,
            size: 36,
            color: AppConstants.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Drag & drop your Firebase Service Account JSON here',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'or click the button below to browse from your computer',
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => _pickFile(),
          icon: const Icon(Icons.folder_open_rounded, size: 18),
          label: const Text('Browse JSON File'),
        ),
      ],
    );
  }

  Widget _buildConnectedView(
      BuildContext context, ProjectProvider projectProvider, dynamic session) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppConstants.success,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Firebase Project Active',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppConstants.success,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Project ID: ${session.projectId}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (session.clientEmail.isNotEmpty)
                    Text(
                      'Client Email: ${session.clientEmail}',
                      style: theme.textTheme.bodySmall,
                    ),
                  if (projectProvider.fileName != null)
                    Text(
                      'File: ${projectProvider.fileName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: () => _pickFile(),
              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
              label: const Text('Replace Credentials'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.error,
              ),
              onPressed: () async {
                await projectProvider.disconnect();
              },
              icon: const Icon(Icons.power_settings_new_rounded, size: 18),
              label: const Text('Disconnect'),
            ),
          ],
        ),
      ],
    );
  }
}
