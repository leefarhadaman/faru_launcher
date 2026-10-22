import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app/theme.dart';
import '../models/launcher_app.dart';
import '../settings/settings_screen.dart';
import 'app_drawer.dart';
import 'launcher_controller.dart';
import 'launcher_state.dart';
import 'notification_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.controller});
  final LauncherController? controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late final LauncherController _controller;
  late final bool _ownsController;

  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  // Drawer slide
  late final AnimationController _drawerAC;
  late final Animation<Offset> _drawerSlide;
  bool _drawerOpen = false;

  // Notification panel overlay
  bool _notifOpen = false;

  // Swipe detection
  double _dragStartY = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? LauncherController();
    _controller.initialize();

    _drawerAC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    _drawerSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _drawerAC, curve: Curves.easeOutCubic));

    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
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
    _drawerAC.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _openDrawer() {
    setState(() => _drawerOpen = true);
    _drawerAC.forward(from: 0);
  }

  Future<void> _closeDrawer() async {
    await _drawerAC.reverse();
    if (mounted) {
      setState(() {
        _drawerOpen = false;
        _searchQuery = '';
      });
    }
  }

  void _openNotifPanel() => setState(() => _notifOpen = true);
  void _closeNotifPanel() => setState(() => _notifOpen = false);

  Future<void> _handleAppTap(LauncherApp app) async {
    if (_drawerOpen) await _closeDrawer();
    final launched = await _controller.launchApp(app);
    if (!mounted || launched) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _controller.state.launchErrorMessage ?? 'Unable to open ${app.label}',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xCC1E1E2E),
      ),
    );
  }

  String _timeStr(DateTime dt) {
    final use24 = MediaQuery.alwaysUse24HourFormatOf(context);
    final h = use24
        ? dt.hour.toString().padLeft(2, '0')
        : ((dt.hour % 12 == 0) ? 12 : dt.hour % 12).toString();
    final m = dt.minute.toString().padLeft(2, '0');
    return use24 ? '$h:$m' : '$h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }

  String _dateStr(DateTime dt) {
    const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const mo = [
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
    return '${wd[dt.weekday - 1]}, ${mo[dt.month - 1]} ${dt.day}';
  }

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FaruTheme.scaffoldBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background SVG
          SvgPicture.asset('assets/bg.svg', fit: BoxFit.cover),

          // Vignette
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x77000000),
                  Color(0x00000000),
                  Color(0x00000000),
                  Color(0xCC000000),
                ],
                stops: [0.0, 0.18, 0.65, 1.0],
              ),
            ),
          ),

          // Home content (swipe up = drawer, swipe down = notif)
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragStart: (d) => _dragStartY = d.localPosition.dy,
            onVerticalDragEnd: (d) {
              final dy = d.primaryVelocity ?? 0;
              final delta = d.localPosition.dy - _dragStartY;
              if (dy < -400 || delta < -80) {
                _openDrawer();
              }
              if (dy > 600 || delta > 80) {
                _openNotifPanel();
              }
            },
            child: SafeArea(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (ctx, _) => _buildHome(ctx, _controller.state),
              ),
            ),
          ),

          // App drawer (slides up from bottom)
          if (_drawerOpen) _buildDrawerOverlay(),

          // Notification panel (slides down from top)
          if (_notifOpen) NotificationPanel(onClose: _closeNotifPanel),
        ],
      ),
    );
  }

  // ── Home screen content ────────────────────────────────────────────────
  Widget _buildHome(BuildContext ctx, LauncherState state) {
    final favorites = state.favoriteApps;
    return Column(
      children: [
        // Top row — settings icon
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 16, top: 8),
            child: _GlassIconBtn(
              icon: Icons.tune,
              onTap: () => Navigator.of(ctx).push(
                MaterialPageRoute<void>(
                  builder: (_) => SettingsScreen(controller: _controller),
                ),
              ),
            ),
          ),
        ),

        const Spacer(),

        // Clock — right-aligned, large thin font
        Padding(
          padding: const EdgeInsets.only(right: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _timeStr(_now),
                style: Theme.of(ctx).textTheme.headlineLarge
                    ?.copyWith(fontSize: 68, fontWeight: FontWeight.w100),
              ),
              Text(_dateStr(_now), style: Theme.of(ctx).textTheme.bodyMedium),
            ],
          ),
        ),

        const SizedBox(height: 40),

        // Favorite apps — right-aligned text with dot bullet
        if (favorites.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: favorites.take(8).map((app) {
                return _FavoriteRow(app: app, onTap: () => _handleAppTap(app));
              }).toList(),
            ),
          ),

        const SizedBox(height: 32),

        // Swipe hint
        Column(
          children: [
            const Icon(
              Icons.keyboard_arrow_up,
              color: Color(0x44FFFFFF),
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              'swipe up for all apps',
              style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                color: const Color(0x44FFFFFF),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  // ── Drawer overlay ─────────────────────────────────────────────────────
  Widget _buildDrawerOverlay() {
    return SlideTransition(
      position: _drawerSlide,
      child: GestureDetector(
        onVerticalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0) > 400) _closeDrawer();
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xF00A0A0E), Color(0xF50D0D12)],
            ),
          ),
          child: SafeArea(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (ctx, _) {
                final state = _controller.state;
                return Column(
                  children: [
                    // Drag handle + close
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Apps',
                            style: TextStyle(
                              color: FaruTheme.textSecondary,
                              fontSize: 13,
                              letterSpacing: 1.5,
                            ),
                          ),
                          GestureDetector(
                            onTap: _closeDrawer,
                            child: const Icon(
                              Icons.keyboard_arrow_down,
                              color: FaruTheme.textSecondary,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: AppDrawer(
                        apps: state.allApps,
                        favoritePackages: state.favoritePackages,
                        onAppTap: _handleAppTap,
                        onToggleFavorite: (app) =>
                            _controller.toggleFavorite(app.packageName),
                        searchQuery: _searchQuery,
                        onSearchChanged: (q) {
                          setState(() => _searchQuery = q);
                          _controller.updateSearchQuery(q);
                        },
                        onClose: _closeDrawer,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ── Favorite row (home screen) ─────────────────────────────────────────────
class _FavoriteRow extends StatelessWidget {
  const _FavoriteRow({required this.app, required this.onTap});
  final LauncherApp app;
  final VoidCallback onTap;

  // Deterministic color from package name
  Color _dotColor() {
    const colors = [
      Color(0xFF7DD3FC),
      Color(0xFFB794F4),
      Color(0xFF6EE7B7),
      Color(0xFFFCA5A5),
      Color(0xFFFCD34D),
      Color(0xFF93C5FD),
    ];
    return colors[app.packageName.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dot bullet
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _dotColor(),
              ),
            ),
            Text(
              app.label,
              style: const TextStyle(
                color: FaruTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w300,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small glass icon button ────────────────────────────────────────────────
class _GlassIconBtn extends StatelessWidget {
  const _GlassIconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '',
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0x22FFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x22FFFFFF), width: 0.6),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: FaruTheme.textSecondary, size: 18),
            ),
          ),
        ),
      ),
    );
  }
}
