import 'package:flutter/material.dart';
import '../utils/constants.dart';

class MobileNotificationPreview extends StatelessWidget {
  final String title;
  final String body;
  final String? imageUrl;
  final String platform; // 'android' | 'ios'
  final ValueChanged<String>? onPlatformChanged;

  const MobileNotificationPreview({
    super.key,
    required this.title,
    required this.body,
    this.imageUrl,
    this.platform = 'android',
    this.onPlatformChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIos = platform.toLowerCase() == 'ios';

    final displayTitle = title.trim().isEmpty ? 'Notification Title Preview' : title.trim();
    final displayBody = body.trim().isEmpty
        ? 'Your message content will appear right here on the target device...'
        : body.trim();

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
                    const Icon(Icons.phone_android_rounded, size: 20, color: AppConstants.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Live Device Preview',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Platform Switcher (Android / iOS)
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
                      _buildPlatformButton(
                        context: context,
                        label: 'Android',
                        icon: Icons.android_rounded,
                        isSelected: !isIos,
                        onTap: () => onPlatformChanged?.call('android'),
                      ),
                      const SizedBox(width: 2),
                      _buildPlatformButton(
                        context: context,
                        label: 'iOS (APNs)',
                        icon: Icons.apple_rounded,
                        isSelected: isIos,
                        onTap: () => onPlatformChanged?.call('ios'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Realistic Device Mockup Frame
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 380),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isIos
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [const Color(0xFF182234), const Color(0xFF0B132B)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Phone status bar mockup
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '9:41',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        // Camera notch / Dynamic island
                        Container(
                          width: isIos ? 90 : 12,
                          height: isIos ? 18 : 12,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(isIos ? 12 : 6),
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.wifi_rounded, size: 14, color: Colors.white.withValues(alpha: 0.8)),
                            const SizedBox(width: 4),
                            Icon(Icons.battery_full_rounded, size: 14, color: Colors.white.withValues(alpha: 0.8)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Notification banner container
                    isIos
                        ? _buildIosBanner(displayTitle, displayBody)
                        : _buildAndroidBanner(displayTitle, displayBody),

                    const SizedBox(height: 24),
                    // Home bar line
                    Container(
                      width: 100,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            // Helpful note regarding notification delivery
            Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: AppConstants.primaryLight),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isIos
                        ? 'iOS uses Apple Push Notification service (APNs). Ensure your APNs key is linked in Firebase.'
                        : 'Android uses FCM HTTP v1 with high priority and "high_importance_channel".',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformButton({
    required BuildContext context,
    required String label,
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
              label,
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

  Widget _buildAndroidBanner(String title, String body) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  width: 20,
                  height: 20,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppConstants.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.notifications_active_rounded, size: 12, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'PushPilot',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Text(' • ', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              const Text(
                'now',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
              ),
              const Spacer(),
              const Icon(Icons.expand_more_rounded, size: 16, color: Color(0xFF94A3B8)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 12,
              height: 1.3,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (hasImage) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl!.trim(),
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 60,
                  color: Colors.black26,
                  child: const Center(
                    child: Text(
                      'Failed to load image preview',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIosBanner(String title, String body) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  width: 20,
                  height: 20,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppConstants.primary,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Icon(Icons.rocket_launch_rounded, size: 12, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'PUSHPILOT',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              const Text(
                'now',
                style: TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            body,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          if (hasImage) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl!.trim(),
                height: 110,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
