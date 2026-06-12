import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/glass_bottom_sheet.dart';
import '../../providers/providers.dart';

// ── Login-screen navy + blue nav palette ───────────────────────────
class _C {
  static const activeF  = Color(0xFF1D4ED8); // deep blue
  static const activeF2 = Color(0xFF0EA5E9); // sky blue
  static const logoA    = Color(0xFF1D4ED8); // blue (matches login button)
  static const logoB    = Color(0xFF0EA5E9); // sky
}

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static const _bottomItems = [
    _NavItem(icon: Icons.dashboard_rounded,              label: 'Home',   path: '/'),
    _NavItem(icon: Icons.shopping_cart_rounded,          label: 'Shop',   path: '/shopping'),
    _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Budget', path: '/budget'),
    _NavItem(icon: Icons.favorite_rounded,               label: 'Health', path: '/health'),
  ];

  static const _moreItems = [
    _NavItem(icon: Icons.cleaning_services_rounded,  label: 'Cleaning',   path: '/cleaning'),
    _NavItem(icon: Icons.receipt_long_rounded,       label: 'Expenses',   path: '/expenses'),
    _NavItem(icon: Icons.restaurant_menu_rounded,    label: 'Food',       path: '/food'),
    _NavItem(icon: Icons.auto_awesome_rounded,       label: 'AI Advisor', path: '/advisor'),
    _NavItem(icon: Icons.favorite_border_rounded,    label: 'Wish List',  path: '/wishlist'),
  ];

  // flat list — no group headers, TASKHUB style
  List<_NavItem> _buildNavItems(bool isAdmin) => [
    const _NavItem(icon: Icons.dashboard_rounded,              label: 'Dashboard',      path: '/'),
    const _NavItem(icon: Icons.cleaning_services_rounded,      label: 'Cleaning',       path: '/cleaning'),
    const _NavItem(icon: Icons.shopping_cart_rounded,          label: 'Shopping',       path: '/shopping'),
    const _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Budget',         path: '/budget'),
    const _NavItem(icon: Icons.receipt_long_rounded,           label: 'Expenses',       path: '/expenses'),
    const _NavItem(icon: Icons.favorite_rounded,               label: 'Health',         path: '/health'),
    const _NavItem(icon: Icons.restaurant_menu_rounded,        label: 'Food Tracker',   path: '/food'),
    const _NavItem(icon: Icons.favorite_border_rounded,        label: 'Wish List',      path: '/wishlist'),
    const _NavItem(icon: Icons.auto_awesome_rounded,           label: 'AI Advisor',     path: '/advisor'),
    if (isAdmin)
      const _NavItem(icon: Icons.health_and_safety_rounded,   label: 'PCOS Guide',     path: '/pcos-guide'),
  ];

  void _navigate(String path) => context.go(path);

  @override
  Widget build(BuildContext context) {
    final isDark      = ref.watch(themeModeProvider);
    final isAdmin     = ref.watch(isAdminProvider);
    final isWide      = MediaQuery.of(context).size.width >= 800;
    final currentPath = GoRouterState.of(context).uri.path;
    final navItems    = _buildNavItems(isAdmin);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF071223) : const Color(0xFFF1F5F9),
      appBar: isWide ? null : _buildAppBar(context, isDark, currentPath),
      body: isWide
          ? Row(children: [
              _TaskHubSidebar(
                items: navItems,
                currentPath: currentPath,
                onNavigate: _navigate,
                onSignOut: () => ref.read(authServiceProvider).signOut(),
                isDark: isDark,
                onToggleTheme: () => ref.read(themeModeProvider.notifier).state = !isDark,
              ),
              Expanded(child: widget.child),
            ])
          : widget.child,
      bottomNavigationBar: isWide
          ? null
          : _TaskHubBottomBar(
              items: _bottomItems,
              moreItems: _moreItems,
              currentPath: currentPath,
              onNavigate: _navigate,
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, bool isDark, String currentPath) {
    final appBarBg  = isDark ? const Color(0xFF071223) : Colors.white;
    final titleCol  = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedCol  = isDark ? const Color(0xFF7096B8) : const Color(0xFF6B7280);
    return AppBar(
      backgroundColor: appBarBg,
      elevation: 0,
      title: Row(children: [
        _LogoBadge(size: 30),
        const SizedBox(width: 10),
        Text('HomeSync',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: titleCol,
              letterSpacing: -0.3,
            )),
      ]),
      actions: [
        IconButton(
          icon: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            size: 19,
            color: mutedCol,
          ),
          onPressed: () =>
              ref.read(themeModeProvider.notifier).state = !isDark,
        ),
        IconButton(
          icon: Icon(Icons.notifications_outlined, size: 19, color: mutedCol),
          onPressed: () => context.push('/settings'),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// ── Logo badge ──────────────────────────────────────────────────────
class _LogoBadge extends StatelessWidget {
  final double size;
  const _LogoBadge({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_C.logoA, _C.logoB],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: _C.logoA.withValues(alpha: 0.40),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(Icons.home_rounded,
          color: Colors.white, size: size * 0.50),
    );
  }
}

// ── Sidebar ─────────────────────────────────────────────────────────
class _TaskHubSidebar extends StatelessWidget {
  final List<_NavItem> items;
  final String currentPath;
  final ValueChanged<String> onNavigate;
  final VoidCallback onSignOut;
  final bool isDark;
  final VoidCallback onToggleTheme;

  const _TaskHubSidebar({
    required this.items,
    required this.currentPath,
    required this.onNavigate,
    required this.onSignOut,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF071223) : Colors.white;
    final dividerColor = isDark ? const Color(0x1438BDF8) : const Color(0x18000000);
    final mutedText = isDark ? const Color(0xFF7096B8) : const Color(0xFF6B7280);

    return Container(
      width: 226,
      color: bg,
      child: SafeArea(
        child: Column(children: [
          // Brand
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(children: [
              _LogoBadge(size: 38),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('HomeSync',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    )),
                Text('Smart Home Manager',
                    style: TextStyle(
                      fontSize: 10,
                      color: mutedText,
                      fontWeight: FontWeight.w400,
                    )),
              ]),
            ]),
          ),
          Divider(height: 1, color: dividerColor),
          const SizedBox(height: 8),
          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: items
                  .map((item) => _SidebarTile(
                        item: item,
                        active: currentPath == item.path,
                        onTap: () => onNavigate(item.path),
                      ))
                  .toList(),
            ),
          ),
          Divider(height: 1, color: dividerColor),
          // Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                child: Row(
                  children: [
                    Icon(
                      isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      size: 14,
                      color: mutedText,
                    ),
                    const SizedBox(width: 8),
                    Text(isDark ? 'Dark mode' : 'Light mode',
                        style: TextStyle(fontSize: 12, color: mutedText, fontWeight: FontWeight.w400)),
                    const Spacer(),
                    Switch.adaptive(
                      value: isDark,
                      onChanged: (_) => onToggleTheme(),
                      activeThumbColor: const Color(0xFF38BDF8),
                      activeTrackColor: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),
              _SidebarTile(
                item: const _NavItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    path: '/settings'),
                active: currentPath == '/settings',
                onTap: () => onNavigate('/settings'),
              ),
              _SidebarTile(
                item: const _NavItem(
                    icon: Icons.logout_rounded,
                    label: 'Sign Out',
                    path: ''),
                active: false,
                onTap: onSignOut,
                isDestructive: true,
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final _NavItem item;
  final bool active;
  final bool isDestructive;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.item,
    required this.active,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedIcon = isDark ? const Color(0xFF4A6A8A) : const Color(0xFF9CA3AF);
    final mutedTxt  = isDark ? const Color(0xFF7096B8) : const Color(0xFF6B7280);

    final iconCol = isDestructive
        ? const Color(0xFFFB7185)
        : active
            ? Colors.white
            : mutedIcon;
    final textCol = isDestructive
        ? const Color(0xFFFB7185)
        : active
            ? Colors.white
            : mutedTxt;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: _C.activeF.withValues(alpha: 0.12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: active
                  ? const LinearGradient(
                      colors: [_C.activeF, _C.activeF2],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Icon(item.icon, size: 17, color: iconCol),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: textCol,
                    fontWeight:
                        active ? FontWeight.w600 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Bottom tab bar ───────────────────────────────────────────────────
class _TaskHubBottomBar extends StatelessWidget {
  final List<_NavItem> items;
  final List<_NavItem> moreItems;
  final String currentPath;
  final ValueChanged<String> onNavigate;

  const _TaskHubBottomBar({
    required this.items,
    required this.moreItems,
    required this.currentPath,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF071223) : Colors.white;
    final dividerColor = isDark ? const Color(0x1438BDF8) : const Color(0x18000000);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(children: [
            for (final item in items)
              Expanded(
                child: _BottomTab(
                  item: item,
                  active: currentPath == item.path,
                  onTap: () => onNavigate(item.path),
                ),
              ),
            Expanded(
              child: _MoreTab(
                  moreItems: moreItems, onNavigate: onNavigate),
            ),
          ]),
        ),
      ),
    );
  }
}

class _BottomTab extends StatelessWidget {
  final _NavItem item;
  final bool active;
  final VoidCallback onTap;
  const _BottomTab(
      {required this.item, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedIcon = isDark ? const Color(0xFF4A6A8A) : const Color(0xFF9CA3AF);
    final mutedTxt  = isDark ? const Color(0xFF7096B8) : const Color(0xFF6B7280);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40,
          height: 32,
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    colors: [_C.activeF, _C.activeF2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(item.icon,
              size: 18,
              color: active ? Colors.white : mutedIcon),
        ),
        const SizedBox(height: 2),
        Text(
          item.label,
          style: TextStyle(
            fontSize: 10,
            color: active ? Colors.white : mutedTxt,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ]),
    );
  }
}

class _MoreTab extends StatelessWidget {
  final List<_NavItem> moreItems;
  final ValueChanged<String> onNavigate;
  const _MoreTab({required this.moreItems, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedIcon = isDark ? const Color(0xFF4A6A8A) : const Color(0xFF9CA3AF);
    final mutedTxt  = isDark ? const Color(0xFF7096B8) : const Color(0xFF6B7280);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showGlassSheet(
        context: context,
        title: 'More',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: moreItems
              .map((item) => ListTile(
                    leading: Icon(item.icon,
                        color: _C.activeF2, size: 20),
                    title: Text(item.label,
                        style: AppTextStyles.bodyMedium),
                    onTap: () {
                      Navigator.pop(context);
                      onNavigate(item.path);
                    },
                  ))
              .toList(),
        ),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 40,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.grid_view_rounded,
              size: 18, color: mutedIcon),
        ),
        const SizedBox(height: 2),
        Text('More',
            style: TextStyle(
                fontSize: 10,
                color: mutedTxt,
                fontWeight: FontWeight.w400)),
      ]),
    );
  }
}

// ── Data classes ──────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label, path;
  const _NavItem(
      {required this.icon, required this.label, required this.path});
}
