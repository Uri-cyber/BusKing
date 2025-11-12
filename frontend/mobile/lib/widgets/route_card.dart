import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/route.dart';
import '../config/app_theme.dart';
import '../config/app_config.dart';
import '../providers/route_provider.dart';

class RouteCard extends StatelessWidget {
  final UserRoute route;

  const RouteCard({super.key, required this.route});

  String _formatDays(List<int> days) {
    if (days.length == 7) return 'כל יום';
    if (days.length == 5 && !days.contains(0) && !days.contains(6)) {
      return 'ימי א-ה';
    }
    return days.map((d) => AppConfig.daysOfWeek[d]).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final routeProvider = Provider.of<RouteProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Route Number Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    route.routeNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Route Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (route.routeName != null)
                        Text(
                          route.routeName!,
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (route.stopName != null)
                        Text(
                          route.stopName!,
                          style: AppTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                // Active Switch
                Switch(
                  value: route.isActive,
                  onChanged: (value) {
                    routeProvider.toggleRoute(route.id, value);
                  },
                ),
              ],
            ),
            const Divider(height: 24),
            // Schedule Info
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  _formatDays(route.daysOfWeek),
                  style: AppTheme.bodySmall,
                ),
                const SizedBox(width: 20),
                const Icon(Icons.access_time, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  '${route.timeWindowStart} - ${route.timeWindowEnd}',
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.notifications, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'התרעה ${route.alertMinutesBefore} דקות לפני',
                  style: AppTheme.bodySmall,
                ),
                const Spacer(),
                // Delete Button
                IconButton(
                  icon: const Icon(Icons.delete, color: AppTheme.error),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('מחק מסלול'),
                        content: const Text('האם אתה בטוח?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('ביטול'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.error,
                            ),
                            child: const Text('מחק'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      final success = await routeProvider.deleteRoute(route.id);
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('המסלול נמחק'),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
