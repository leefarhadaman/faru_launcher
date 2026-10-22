import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app/theme.dart';
import '../models/launcher_app.dart';

// ── Section model ──────────────────────────────────────────────────────────
class _Section {
  _Section(this.letter, this.apps);
  final String letter;
  final List<LauncherApp> apps;
}

List<_Section> _buildSections(List<LauncherApp> apps) {
  final map = <String, List<LauncherApp>>{};
  for (final app in apps) {
    final first = app.label.isNotEmpty ? app.label[0].toUpperCase() : '#';
    final key = RegExp(r'[A-Z]').hasMatch(first) ? first : '#';
    map.putIfAbsent(key, () => []).add(app);
  }
  final keys = map.keys.toList()..sort((a, b) {
    if (a == '#') return 1;
    if (b == '#') return -1;
    return a.compareTo(b);
  });
  return keys.map((k) => _Section(k, map[k]!)).toList();
}

// ── App Drawer ─────────────────────────────────────────────────────────────
class AppDrawer extends StatefulWidget {
  const AppDrawer({
    super.key,
    required this.apps,
    required this.favoritePackages,
    required this.onAppTap,
    required this.onToggleFavorite,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onClose,
  });

  final List<LauncherApp> apps;
  final List<String> favoritePackages;
  final ValueChanged<LauncherApp> onAppTap;
  final ValueChanged<LauncherApp> onToggleFavorite;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClose;

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scroll;
  late final TextEditingController _searchCtrl;
  late final AnimationController _letterAC;
  late final Animation<double> _letterFade;
  late final Animation<double> _letterScale;

  List<_Section> _sections = [];
  String _jumpLetter = '';
  bool _showJumpLetter = false;

  // Pre-computed section offsets for fast jump
  final Map<String, double> _sectionOffsets = {};
  // Approximate item height
  static const double _headerH = 40.0;
  static const double _rowH    = 52.0;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController();
    _searchCtrl = TextEditingController(text: widget.searchQuery);

    _letterAC = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 180));
    _letterFade  = CurvedAnimation(parent: _letterAC, curve: Curves.easeOut);
    _letterScale = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _letterAC, curve: Curves.easeOutBack));

    _rebuild();
  }

  @override
  void didUpdateWidget(AppDrawer old) {
    super.didUpdateWidget(old);
    if (old.apps != widget.apps || old.searchQuery != widget.searchQuery) {
      _rebuild();
    }
    if (old.searchQuery != widget.searchQuery &&
        _searchCtrl.text != widget.searchQuery) {
      _searchCtrl.text = widget.searchQuery;
    }
  }

  void _rebuild() {
    final query = widget.searchQuery.trim().toLowerCase();
    final filtered = query.isEmpty
        ? widget.apps
        : widget.apps.where((a) =>
            a.label.toLowerCase().contains(query) ||
            a.packageName.toLowerCase().contains(query)).toList();

    _sections = _buildSections(filtered);
    _computeOffsets();
  }

  void _computeOffsets() {
    _sectionOffsets.clear();
    double offset = 0;
    for (final sec in _sections) {
      _sectionOffsets[sec.letter] = offset;
      offset += _headerH + sec.apps.length * _rowH;
    }
  }

  void _jumpTo(String letter) {
    HapticFeedback.selectionClick();
    final offset = _sectionOffsets[letter];
    if (offset == null) return;
    _scroll.animateTo(
      offset.clamp(0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
    setState(() {
      _jumpLetter = letter;
      _showJumpLetter = true;
    });
    _letterAC.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      _letterAC.reverse().then((_) {
        if (mounted) setState(() => _showJumpLetter = false);
      });
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchCtrl.dispose();
    _letterAC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Main content ──────────────────────────────────────────────────
        Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: Stack(
                children: [
                  _buildList(),
                  _buildAlphabetSidebar(),
                  if (_showJumpLetter) _buildJumpOverlay(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Search bar ─────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xCC111318),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x28FFFFFF), width: 0.7),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: widget.onSearchChanged,
              style: const TextStyle(color: FaruTheme.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search apps...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                prefixIcon: const Icon(Icons.search,
                    color: FaruTheme.textSecondary, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            color: FaruTheme.textSecondary, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          widget.onSearchChanged('');
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── App list with section headers ───────────────────────────────────────
  Widget _buildList() {
    if (_sections.isEmpty) {
      return const Center(
        child: Text('No apps found',
            style: TextStyle(color: FaruTheme.textSecondary)),
      );
    }

    // Flat list of items: header + rows
    final items = <_ListItem>[];
    for (final sec in _sections) {
      items.add(_ListItem.header(sec.letter));
      for (final app in sec.apps) {
        items.add(_ListItem.app(app));
      }
    }

    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 0, 48, 24),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        if (item.isHeader) {
          return SizedBox(
            height: _headerH,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                item.letter!,
                style: const TextStyle(
                  color: FaruTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          );
        }
        final app = item.app!;
        final pinned = widget.favoritePackages.contains(app.packageName);
        return SizedBox(
          height: _rowH,
          child: _AppRow(
            app: app,
            pinned: pinned,
            onTap: () => widget.onAppTap(app),
            onLongPress: () => widget.onToggleFavorite(app),
          ),
        );
      },
    );
  }

  // ── Right alphabet sidebar ──────────────────────────────────────────────
  Widget _buildAlphabetSidebar() {
    final letters = _sections.map((s) => s.letter).toList();
    if (letters.isEmpty) return const SizedBox.shrink();

    return Positioned(
      right: 4,
      top: 0,
      bottom: 0,
      child: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragUpdate: (d) => _onSidebarDrag(d.localPosition, letters),
          onTapDown: (d) => _onSidebarDrag(d.localPosition, letters),
          child: Container(
            width: 28,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemH = constraints.maxHeight / letters.length;
                return Column(
                  children: letters.map((l) {
                    final active = l == _jumpLetter && _showJumpLetter;
                    return SizedBox(
                      height: itemH,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 150),
                          style: TextStyle(
                            color: active
                                ? FaruTheme.accent
                                : FaruTheme.textSecondary,
                            fontSize: active ? 13 : 10,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                          child: Text(l),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _onSidebarDrag(Offset local, List<String> letters) {
    if (letters.isEmpty) return;
    // Estimate which letter the finger is on
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final sidebarHeight = renderBox.size.height - 16; // minus padding
    final fraction = (local.dy / sidebarHeight).clamp(0.0, 1.0);
    final idx = (fraction * letters.length).floor().clamp(0, letters.length - 1);
    _jumpTo(letters[idx]);
  }

  // ── Big letter overlay ──────────────────────────────────────────────────
  Widget _buildJumpOverlay() {
    return Center(
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _letterFade,
          child: ScaleTransition(
            scale: _letterScale,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: const Color(0xCC1A1A24),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: FaruTheme.accent.withValues(alpha: 0.4), width: 1),
              ),
              alignment: Alignment.center,
              child: Text(
                _jumpLetter,
                style: const TextStyle(
                  color: FaruTheme.accent,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── List item discriminated union ──────────────────────────────────────────
class _ListItem {
  _ListItem.header(this.letter) : app = null, isHeader = true;
  _ListItem.app(this.app) : letter = null, isHeader = false;

  final bool isHeader;
  final String? letter;
  final LauncherApp? app;
}

// ── Single app row ─────────────────────────────────────────────────────────
class _AppRow extends StatelessWidget {
  const _AppRow({
    required this.app,
    required this.pinned,
    required this.onTap,
    required this.onLongPress,
  });

  final LauncherApp app;
  final bool pinned;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        onLongPress: onLongPress,
        splashColor: FaruTheme.accent.withValues(alpha: 0.08),
        highlightColor: FaruTheme.accent.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              if (pinned)
                Container(
                  width: 5, height: 5,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: FaruTheme.accent,
                  ),
                )
              else
                const SizedBox(width: 15),
              Expanded(
                child: Text(
                  app.label,
                  style: TextStyle(
                    color: pinned
                        ? FaruTheme.textPrimary
                        : const Color(0xCCF3F5F8),
                    fontSize: 16,
                    fontWeight: pinned ? FontWeight.w500 : FontWeight.w300,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
