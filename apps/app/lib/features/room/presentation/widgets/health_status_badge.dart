import 'package:app/core/network/backend_health_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HealthStatusBadge extends ConsumerWidget {
  const HealthStatusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthState = ref.watch(backendHealthProvider);

    return healthState.when(
      data: (status) => _buildBadge(context, ref, status),
      loading: () => _buildBadge(context, ref, HealthStatus.checking),
      error: (_, _) => _buildBadge(context, ref, HealthStatus.unreachable),
    );
  }

  Widget _buildBadge(BuildContext context, WidgetRef ref, HealthStatus status) {
    final (color, label, icon) = switch (status) {
      HealthStatus.healthy => (
        Colors.greenAccent,
        'API Ready',
        Icons.check_circle_outline,
      ),
      HealthStatus.unreachable => (
        Colors.redAccent,
        'API Offline',
        Icons.error_outline,
      ),
      HealthStatus.checking => (
        Colors.orangeAccent,
        'Sprawdzanie...',
        Icons.sync,
      ),
    };

    return InkWell(
      onTap: () => ref.read(backendHealthProvider.notifier).verifyHealth(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (status == HealthStatus.unreachable) ...[
              const SizedBox(width: 4),
              const Icon(Icons.refresh, color: Colors.redAccent, size: 14),
            ],
          ],
        ),
      ),
    );
  }
}
