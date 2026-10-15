import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../utils/constants.dart';
import '../widgets/drag_drop_upload.dart';

class CredentialsScreen extends StatelessWidget {
  final ValueChanged<int>? onNavigate;

  const CredentialsScreen({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final projectProvider = Provider.of<ProjectProvider>(context);

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
                    'Firebase Service Account',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your Firebase Admin SDK service account credentials securely',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              if (projectProvider.isConnected)
                ElevatedButton.icon(
                  onPressed: () => onNavigate?.call(1), // Go to Composer
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Go to Composer'),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Upload Widget Card
          DragDropUploadWidget(
            onConnectedSuccess: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Connected to Firebase Project "${projectProvider.session?.projectId}"!',
                  ),
                  backgroundColor: AppConstants.success,
                ),
              );
            },
          ),
          const SizedBox(height: 32),

          // Difference Clarification Card (Very Important Requirement)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppConstants.warningBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppConstants.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_rounded, color: AppConstants.warning, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Important Distinction: Service Account JSON vs. google-services.json',
                        style: TextStyle(
                          color: AppConstants.warning,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '• Service Account Private Key JSON (Required here): Created in Firebase Console > Project Settings > Service Accounts. It contains a "private_key" and allows the server to authenticate directly with Google\'s FCM HTTP v1 API to dispatch notifications.\n\n'
                        '• google-services.json (Client-only): Downloaded for Android apps to initialize Firebase on mobile devices. It does NOT contain a private key and CANNOT be used to send push notifications.',
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Step-by-Step Instructions Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.menu_book_rounded, color: AppConstants.primary, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'How to generate a Firebase Service Account JSON',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInstructionStep(
                    stepNumber: '1',
                    title: 'Open Firebase Console',
                    description:
                        'Navigate to https://console.firebase.google.com and open your Firebase project.',
                  ),
                  const SizedBox(height: 16),
                  _buildInstructionStep(
                    stepNumber: '2',
                    title: 'Navigate to Project Settings',
                    description:
                        'Click the Settings Gear icon (⚙️) next to "Project Overview" in the left sidebar and choose "Project settings".',
                  ),
                  const SizedBox(height: 16),
                  _buildInstructionStep(
                    stepNumber: '3',
                    title: 'Open the "Service accounts" tab',
                    description:
                        'Click the "Service accounts" tab at the top of the settings page. Select "Node.js" as the configuration snippet.',
                  ),
                  const SizedBox(height: 16),
                  _buildInstructionStep(
                    stepNumber: '4',
                    title: 'Generate New Private Key',
                    description:
                        'Click the blue "Generate new private key" button, then confirm by clicking "Generate key". Your browser will download a JSON file.',
                  ),
                  const SizedBox(height: 16),
                  _buildInstructionStep(
                    stepNumber: '5',
                    title: 'Upload to PushPilot',
                    description:
                        'Drag & drop that downloaded JSON file into the upload zone above or click "Browse JSON File".',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Security Guarantee Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppConstants.success.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.security_rounded, color: AppConstants.success, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Zero-Retention In-Memory Security',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'PushPilot never stores your private keys on disk or in any database. Keys are initialized strictly in-memory inside the secure backend process and can be disconnected at any time.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep({
    required String stepNumber,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppConstants.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: AppConstants.primary.withValues(alpha: 0.3)),
          ),
          child: Text(
            stepNumber,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppConstants.primary,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
