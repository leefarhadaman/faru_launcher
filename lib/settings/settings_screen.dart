import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../launcher/launcher_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.controller,
  });

  final LauncherController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auvriko Settings'),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final state = controller.state;
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: <Widget>[
                Text(
                  'DISPLAY & PRODUCTIVITY',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: FaruTheme.accent,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show date & time header'),
                  subtitle: const Text(
                    'Display current local time and date on the home screen.',
                  ),
                  value: state.showClock,
                  onChanged: controller.setShowClock,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Save recent search queries'),
                  subtitle: const Text(
                    'Store recent search terms locally on this device (opt-in).',
                  ),
                  value: state.recentSearchEnabled,
                  onChanged: controller.setRecentSearchEnabled,
                ),
                if (state.recentSearchEnabled &&
                    state.recentSearches.isNotEmpty)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Clear recent search history'),
                    subtitle: Text(
                      '${state.recentSearches.length} saved search queries',
                    ),
                    trailing: TextButton(
                      onPressed: controller.clearRecentSearches,
                      child: const Text('Clear'),
                    ),
                  ),
                const Divider(color: FaruTheme.surfaceBorder, height: 32),
                Text(
                  'APP DISCOVERY',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: FaruTheme.accent,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Refresh installed applications'),
                  subtitle: Text(
                    '${state.allApps.length} launchable apps currently indexed',
                  ),
                  trailing: OutlinedButton.icon(
                    onPressed: () => controller.loadApps(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh'),
                  ),
                ),
                const Divider(color: FaruTheme.surfaceBorder, height: 32),
                Text(
                  'PRIVACY & ABOUT',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: FaruTheme.accent,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('On-device privacy guarantee'),
                  subtitle: Text(
                    'Auvriko keeps your installed app list, favorites, and search history strictly on-device. No analytics or network calls are used.',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
