import 'dart:ui';

import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../services/notification_service.dart';
import '../services/toggle_service.dart';

class NotificationPanel extends StatefulWidget {
  const NotificationPanel({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  State<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  ToggleStates _toggles = const ToggleStates();
  List<AppNotification> _notifications = [];
  bool _hasPermission = false;
  double _brightness = 128;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ac, curve: Curves.easeIn);
    _ac.forward();
    _load();
    NotificationService.setChangedListener(_refreshNotifications);
  }

  @override
  void dispose() {
    NotificationService.setChangedListener(null);
    _ac.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final s = await ToggleService.getStates();
    final p = await NotificationService.isPermissionGranted();
    final n = p
        ? await NotificationService.getNotifications()
        : <AppNotification>[];
    if (!mounted) return;
    setState(() {
      _toggles = s;
      _brightness = s.brightness.toDouble();
      _hasPermission = p;
      _notifications = n;
    });
  }

  Future<void> _refreshNotifications() async {
    final n = await NotificationService.getNotifications();
    if (!mounted) return;
    setState(() => _notifications = n);
  }

  Future<void> _close() async {
    await _ac.reverse();
    widget.onClose();
  }

  Future<void> _tap(String action) async {
    switch (action) {
      case 'wifi':
        await ToggleService.toggleWifi();
        break;
      case 'bt':
        await ToggleService.toggleBluetooth();
        break;
      case 'torch':
        await ToggleService.toggleTorch();
        break;
      case 'airplane':
        await ToggleService.toggleAirplane();
        break;
      case 'dnd':
        await ToggleService.toggleDnd();
        break;
    }
    final s = await ToggleService.getStates();
    if (!mounted) return;
    setState(() => _toggles = s);
  }

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: GestureDetector(
        onTap: _close,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: Colors.black54,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () {}, // absorb taps inside panel
            child: SlideTransition(
              position: _slide,
              child: _PanelSheet(
                toggles: _toggles,
                notifications: _notifications,
                hasPermission: _hasPermission,
                brightness: _brightness,
                onTap: _tap,
                onBrightnessChange: (v) async {
                  setState(() => _brightness = v);
                  await ToggleService.setBrightness(v.round());
                },
                onDismiss: (key) async {
                  await NotificationService.dismiss(key);
                  await _refreshNotifications();
                },
                onRequestPermission: () async {
                  await NotificationService.requestPermission();
                },
                onClose: _close,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Panel sheet ────────────────────────────────────────────────────────────
class _PanelSheet extends StatelessWidget {
  const _PanelSheet({
    required this.toggles,
    required this.notifications,
    required this.hasPermission,
    required this.brightness,
    required this.onTap,
    required this.onBrightnessChange,
    required this.onDismiss,
    required this.onRequestPermission,
    required this.onClose,
  });

  final ToggleStates toggles;
  final List<AppNotification> notifications;
  final bool hasPermission;
  final double brightness;
  final ValueChanged<String> onTap;
  final ValueChanged<double> onBrightnessChange;
  final ValueChanged<String> onDismiss;
  final VoidCallback onRequestPermission;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(maxHeight: mq.size.height * 0.82),
          decoration: BoxDecoration(
            color: const Color(0xE0101014),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(28),
            ),
            border: const Border(
              bottom: BorderSide(color: Color(0x22FFFFFF), width: 0.5),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                const SizedBox(height: 10),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0x44FFFFFF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // Quick toggle grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _ToggleGrid(toggles: toggles, onTap: onTap),
                ),

                const SizedBox(height: 20),

                // Brightness slider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.brightness_low,
                        color: FaruTheme.textSecondary,
                        size: 18,
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 7,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 14,
                            ),
                            trackHeight: 3,
                            activeTrackColor: FaruTheme.accent,
                            inactiveTrackColor: const Color(0x33FFFFFF),
                            thumbColor: Colors.white,
                            overlayColor: FaruTheme.accent.withValues(
                              alpha: 0.2,
                            ),
                          ),
                          child: Slider(
                            value: brightness.clamp(0, 255),
                            min: 0,
                            max: 255,
                            onChanged: onBrightnessChange,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.brightness_high,
                        color: FaruTheme.textSecondary,
                        size: 18,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(color: Color(0x22FFFFFF), height: 1),
                const SizedBox(height: 8),

                // Notifications section
                Flexible(
                  child: _NotificationList(
                    notifications: notifications,
                    hasPermission: hasPermission,
                    onDismiss: onDismiss,
                    onRequestPermission: onRequestPermission,
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Toggle grid ────────────────────────────────────────────────────────────
class _ToggleGrid extends StatelessWidget {
  const _ToggleGrid({required this.toggles, required this.onTap});
  final ToggleStates toggles;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      _TileData('wifi', Icons.wifi, 'Wi-Fi', toggles.wifi),
      _TileData('bt', Icons.bluetooth, 'Bluetooth', toggles.bluetooth),
      _TileData('torch', Icons.flashlight_on, 'Flashlight', toggles.torch),
      _TileData('dnd', Icons.do_not_disturb_on, 'DnD', false),
      _TileData(
        'airplane',
        Icons.airplanemode_active,
        'Airplane',
        toggles.airplane,
      ),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items
          .map((d) => _ToggleTile(data: d, onTap: () => onTap(d.id)))
          .toList(),
    );
  }
}

class _TileData {
  const _TileData(this.id, this.icon, this.label, this.active);
  final String id;
  final IconData icon;
  final String label;
  final bool active;
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({required this.data, required this.onTap});
  final _TileData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: data.active
                  ? FaruTheme.accent.withValues(alpha: 0.25)
                  : const Color(0xFF1E1E28),
              border: Border.all(
                color: data.active
                    ? FaruTheme.accent.withValues(alpha: 0.7)
                    : const Color(0x33FFFFFF),
                width: 1,
              ),
            ),
            child: Icon(
              data.icon,
              color: data.active ? FaruTheme.accent : FaruTheme.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.label,
            style: const TextStyle(
              color: FaruTheme.textSecondary,
              fontSize: 10,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notification list ──────────────────────────────────────────────────────
class _NotificationList extends StatelessWidget {
  const _NotificationList({
    required this.notifications,
    required this.hasPermission,
    required this.onDismiss,
    required this.onRequestPermission,
  });

  final List<AppNotification> notifications;
  final bool hasPermission;
  final ValueChanged<String> onDismiss;
  final VoidCallback onRequestPermission;

  @override
  Widget build(BuildContext context) {
    if (!hasPermission) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.notifications_off_outlined,
              color: FaruTheme.textSecondary,
              size: 32,
            ),
            const SizedBox(height: 10),
            const Text(
              'Allow Faru to read notifications',
              style: TextStyle(color: FaruTheme.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRequestPermission,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: FaruTheme.accent.withValues(alpha: 0.5),
                ),
                foregroundColor: FaruTheme.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      );
    }

    if (notifications.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'No notifications',
          style: TextStyle(color: FaruTheme.textSecondary, fontSize: 13),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shrinkWrap: true,
      itemCount: notifications.length,
      separatorBuilder: (context, index) =>
          const Divider(color: Color(0x18FFFFFF), height: 1),
      itemBuilder: (_, i) {
        final n = notifications[i];
        return Dismissible(
          key: ValueKey(n.key),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => onDismiss(n.key),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.close, color: Colors.redAccent, size: 18),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App abbreviation circle
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1E1E28),
                    border: Border.all(
                      color: const Color(0x33FFFFFF),
                      width: 0.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    n.appLabel.isNotEmpty ? n.appLabel[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: FaruTheme.accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            n.appLabel,
                            style: const TextStyle(
                              color: FaruTheme.textSecondary,
                              fontSize: 11,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _elapsed(n.postTime),
                            style: const TextStyle(
                              color: FaruTheme.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (n.title.isNotEmpty)
                        Text(
                          n.title,
                          style: const TextStyle(
                            color: FaruTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (n.text.isNotEmpty)
                        Text(
                          n.text,
                          style: const TextStyle(
                            color: FaruTheme.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _elapsed(int postTimeMs) {
    final diff = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(postTimeMs),
    );
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
