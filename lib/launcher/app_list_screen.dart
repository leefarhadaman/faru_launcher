import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../models/launcher_app.dart';

class AppListView extends StatelessWidget {
  const AppListView({
    super.key,
    required this.apps,
    required this.favoriteApps,
    required this.showFavoritesSection,
    required this.isFavorite,
    required this.onAppTap,
    required this.onToggleFavorite,
  });

  final List<LauncherApp> apps;
  final List<LauncherApp> favoriteApps;
  final bool showFavoritesSection;
  final bool Function(String packageName) isFavorite;
  final ValueChanged<LauncherApp> onAppTap;
  final ValueChanged<LauncherApp> onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: <Widget>[
        if (showFavoritesSection && favoriteApps.isNotEmpty) ...<Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Pinned Favorites',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: FaruTheme.accent,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  '${favoriteApps.length} pinned',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          for (final app in favoriteApps)
            AppListTile(
              key: ValueKey<String>('favorite_${app.packageName}'),
              app: app,
              pinned: true,
              onTap: () => onAppTap(app),
              onToggleFavorite: () => onToggleFavorite(app),
            ),
          const SizedBox(height: 12),
          const Divider(color: FaruTheme.surfaceBorder, height: 1),
          const SizedBox(height: 12),
        ],
        for (final app in apps)
          AppListTile(
            key: ValueKey<String>('app_${app.packageName}'),
            app: app,
            pinned: isFavorite(app.packageName),
            onTap: () => onAppTap(app),
            onToggleFavorite: () => onToggleFavorite(app),
          ),
      ],
    );
  }
}

class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.app,
    required this.pinned,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final LauncherApp app;
  final bool pinned;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Launch ${app.label}',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    app.label,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  tooltip: pinned
                      ? 'Unpin ${app.label} from favorites'
                      : 'Pin ${app.label} to favorites',
                  onPressed: onToggleFavorite,
                  icon: Icon(
                    pinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: pinned ? FaruTheme.accent : FaruTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.north_east,
                  size: 16,
                  color: FaruTheme.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
