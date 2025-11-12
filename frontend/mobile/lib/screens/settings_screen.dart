import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('הגדרות'),
      ),
      body: ListView(
        children: [
          // User Info
          Container(
            padding: const EdgeInsets.all(24),
            color: AppTheme.primary.withOpacity(0.1),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primary,
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.name ?? 'משתמש',
                  style: AppTheme.headline2,
                ),
                const SizedBox(height: 8),
                Text(
                  user?.phoneNumber ?? '',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // Settings
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('התרעות'),
            subtitle: Text(
              user?.settings.preferredChannel == 'whatsapp'
                  ? 'WhatsApp'
                  : user?.settings.preferredChannel == 'push'
                      ? 'Push Notifications'
                      : 'SMS',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to notifications settings
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.nightlight),
            title: const Text('מצב שקט'),
            subtitle: const Text('אל תשלח התרעות בלילה'),
            value: user?.settings.quietMode ?? true,
            onChanged: (value) {
              // TODO: Update quiet mode
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('שפה'),
            subtitle: Text(
              user?.settings.language == 'he'
                  ? 'עברית'
                  : user?.settings.language == 'en'
                      ? 'English'
                      : 'العربية',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Change language
            },
          ),
          const Divider(),
          // About
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('אודות'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'BusAlert',
                applicationVersion: '1.0.0',
                applicationIcon: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.directions_bus,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                children: const [
                  Text('התרעות חכמות להגעת אוטובוסים בזמן אמת'),
                ],
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('עזרה'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Show help
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('מדיניות פרטיות'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Show privacy policy
            },
          ),
          const Divider(),
          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.error),
            title: const Text(
              'התנתק',
              style: TextStyle(color: AppTheme.error),
            ),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('התנתקות'),
                  content: const Text('האם אתה בטוח שברצונך להתנתק?'),
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
                      child: const Text('התנתק'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
