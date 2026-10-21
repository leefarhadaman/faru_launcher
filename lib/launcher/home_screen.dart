import 'dart:async';
import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../models/launcher_app.dart';
import '../settings/settings_screen.dart';
import 'app_list_screen.dart';
import 'launcher_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.controller,
  });

  final LauncherController? controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final LauncherController _controller;
  late final bool _ownsController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? LauncherController();
    _controller.initialize();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.loadApps(showLoadingIndicator: false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer?.cancel();
    _searchController.dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleAppTap(LauncherApp app) async {
    final launched = await _controller.launchApp(app);
    if (!mounted) return;
    if (!launched) {
      final error =
          _controller.state.launchErrorMessage ?? 'Unable to open ${app.label}';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  void _applySearchQuery(String query) {
    if (_searchController.text != query) {
      _searchController.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }
    _controller.updateSearchQuery(query);
  }

  String _formatTime(BuildContext context, DateTime dateTime) {
    final use24Hour = MediaQuery.alwaysUse24HourFormatOf(context);
    final hour = use24Hour
        ? dateTime.hour.toString().padLeft(2, '0')
        : ((dateTime.hour % 12 == 0) ? 12 : dateTime.hour % 12).toString();
    final minute = dateTime.minute.toString().padLeft(2, '0');
    if (use24Hour) {
      return '$hour:$minute';
    }
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDate(DateTime dateTime) {
    const weekdays = <String>[
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final weekday = weekdays[dateTime.weekday - 1];
    final month = months[dateTime.month - 1];
    return '$weekday, $month ${dateTime.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final state = _controller.state;
            final countLabel = state.filteredApps.length == 1
                ? '1 app'
                : '${state.filteredApps.length} apps';

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // 1. Brand, tagline, and top actions
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Faru',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              state.showClock
                                  ? '${_formatTime(context, _now)}  •  ${_formatDate(_now)}'
                                  : 'Minimal text-first Android home',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh apps',
                        onPressed: () => _controller.loadApps(),
                        icon: const Icon(Icons.refresh),
                      ),
                      IconButton(
                        tooltip: 'Launcher settings',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  SettingsScreen(controller: _controller),
                            ),
                          );
                        },
                        icon: const Icon(Icons.tune),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. Prominent search field
                  TextField(
                    key: const Key('app_search_field'),
                    controller: _searchController,
                    onChanged: _controller.updateSearchQuery,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search apps...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: FaruTheme.textSecondary,
                      ),
                      suffixIcon: state.searchQuery.isNotEmpty
                          ? IconButton(
                              key: const Key('clear_search_button'),
                              tooltip: 'Clear search',
                              onPressed: () => _applySearchQuery(''),
                              icon: const Icon(
                                Icons.close,
                                color: FaruTheme.textSecondary,
                              ),
                            )
                          : null,
                    ),
                  ),

                  // Optional recent searches row
                  if (state.recentSearchEnabled &&
                      state.recentSearches.isNotEmpty &&
                      state.searchQuery.trim().isEmpty) ...<Widget>[
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: state.recentSearches
                                  .map(
                                    (term) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ActionChip(
                                        label: Text(term),
                                        onPressed: () =>
                                            _applySearchQuery(term),
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _controller.clearRecentSearches,
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 18),

                  // 3. "Applications" heading and filtered count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        'Applications',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        countLabel,
                        key: const Key('filtered_app_count'),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 4. Scrollable text list or Loading / Error / Empty states
                  Expanded(
                    child: _buildBody(context),
                  ),

                  // 5. Small footer/brand line
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Faru Launcher • On-device & private',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final state = _controller.state;

    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Loading applications...'),
          ],
        ),
      );
    }

    if (state.hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.error_outline,
              color: FaruTheme.errorColor,
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              state.errorMessage ?? 'Failed to load installed applications.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: const Key('retry_load_apps_button'),
              onPressed: () => _controller.loadApps(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.filteredApps.isEmpty) {
      final hasQuery = state.searchQuery.trim().isNotEmpty;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              hasQuery
                  ? 'No matching applications for "${state.searchQuery.trim()}"'
                  : 'No launchable applications found',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (hasQuery) ...<Widget>[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _applySearchQuery(''),
                child: const Text('Reset search'),
              ),
            ],
          ],
        ),
      );
    }

    return AppListView(
      apps: state.filteredApps,
      favoriteApps: state.favoriteApps,
      showFavoritesSection: state.searchQuery.trim().isEmpty,
      isFavorite: state.isFavorite,
      onAppTap: _handleAppTap,
      onToggleFavorite: (app) => _controller.toggleFavorite(app.packageName),
    );
  }
}
