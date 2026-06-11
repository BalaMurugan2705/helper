import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/glass_bottom_sheet.dart';
import '../../providers/providers.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  // ── Nav definition ──────────────────────────────────────────
  static const _bottomItems = [
    _NavItem(icon: Icons.dashboard_rounded,              label: 'Home',   path: '/'),
    _NavItem(icon: Icons.shopping_cart_rounded,          label: 'Shop',   path: '/shopping'),
    _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Budget', path: '/budget'),
    _NavItem(icon: Icons.favorite_rounded,               label: 'Health', path: '/health'),
  ];

  static const _moreItems = [
    _NavItem(icon: Icons.cleaning_services_rounded,  label: 'Cleaning',    path: '/cleaning'),
    _NavItem(icon: Icons.receipt_long_rounded,       label: 'Expenses',    path: '/expenses'),
    _NavItem(icon: Icons.restaurant_menu_rounded,    label: 'Food',        path: '/food'),
    _NavItem(icon: Icons.auto_awesome_rounded,       label: 'AI Advisor',  path: '/advisor'),
    _NavItem(icon: Icons.favorite_border_rounded,    label: 'Wish List',   path: '/wishlist'),
  ];

  List<_NavGroup> _buildNavGroups(bool isAdmin) => [
    const _NavGroup(label: 'Overview', items: [
      _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard', path: '/'),
    ]),
    const _NavGroup(label: 'Home', items: [
      _NavItem(icon: Icons.cleaning_services_rounded, label: 'Cleaning',  path: '/cleaning'),
      _NavItem(icon: Icons.shopping_cart_rounded,     label: 'Shopping',  path: '/shopping'),
      _NavItem(icon: Icons.favorite_border_rounded,   label: 'Wish List', path: '/wishlist'),
    ]),
    const _NavGroup(label: 'Finance', items: [
      _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Budget',   path: '/budget'),
      _NavItem(icon: Icons.receipt_long_rounded,           label: 'Expenses', path: '/expenses'),
    ]),
    _NavGroup(label: 'Wellness', items: [
      const _NavItem(icon: Icons.favorite_rounded,        label: 'Health',       path: '/health'),
      const _NavItem(icon: Icons.restaurant_menu_rounded, label: 'Food Tracker', path: '/food'),
      if (isAdmin)
        const _NavItem(icon: Icons.health_and_safety_rounded, label: 'PCOS Guide', path: '/pcos-guide'),
    ]),
  ];

  static const _footerItems = [
    _NavItem(icon: Icons.auto_awesome_rounded,       label: 'AI Advisor',    path: '/advisor'),
    _NavItem(icon: Icons.notifications_outlined,     label: 'Notifications', path: '/settings'),
  ];

  void _navigate(String path) => context.go(path);

  @override
  Widget build(BuildContext context) {
    final isDark   = ref.watch(themeModeProvider);
    final isAdmin  = ref.watch(isAdminProvider);
    final isWide   = MediaQuery.of(context).size.width >= 800;
    final currentPath = GoRouterState.of(context).uri.path;
    final groups = _buildNavGroups(isAdmin);

    return Scaffold(
      backgroundColor: AppColors.darkBase,
      appBar: isWide ? null : _buildAppBar(context, isDark),
      body: isWide
          ? Row(children: [
              _AuroraSidebar(
                groups: groups,
                footerItems: _footerItems,
                currentPath: currentPath,
                onNavigate: _navigate,
                onToggleTheme: () =>
                    ref.read(themeModeProvider.notifier).state = !isDark,
                onSignOut: () => ref.read(authServiceProvider).signOut(),
              ),
              Expanded(child: widget.child),
            ])
          : widget.child,
      bottomNavigationBar: isWide ? null : _AuroraBottomBar(
        items: _bottomItems,
        moreItems: _moreItems,
        currentPath: currentPath,
        onNavigate: _navigate,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      backgroundColor: AppColors.darkSurface,
      elevation: 0,
      title: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.accentDashboard, AppColors.accentPcos],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.home_rounded, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 10),
        Text('HomeSync', style: AppTextStyles.titleMedium),
      ]),
      actions: [
        IconButton(
          icon: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            size: 19,
            color: AppColors.textMuted,
          ),
          onPressed: () =>
              ref.read(themeModeProvider.notifier).state = !isDark,
        ),
        IconButton(
          icon: Icon(Icons.notifications_outlined,
              size: 19, color: AppColors.textMuted),
          onPressed: () => context.push('/settings'),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// ── Sidebar ────────────────────────────────────────────────────
class _AuroraSidebar extends StatelessWidget {
  final List<_NavGroup> groups;
  final List<_NavItem>  footerItems;
  final String currentPath;
  final ValueChanged<String> onNavigate;
  final VoidCallback onToggleTheme, onSignOut;

  const _AuroraSidebar({
    required this.groups,
    required this.footerItems,
    required this.currentPath,
    required this.onNavigate,
    required this.onToggleTheme,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: AppColors.darkSurface,
      child: SafeArea(
        child: Column(children: [
          _SidebarBrand(),
          const Divider(height: 1, color: Color(0x0FFFFFFF)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              children: [
                for (final group in groups) ...[
                  _GroupLabel(group.label),
                  for (final item in group.items)
                    _SidebarTile(
                      item: item,
                      active: currentPath == item.path,
                      onTap: () => onNavigate(item.path),
                    ),
                  const SizedBox(height: 4),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0x0FFFFFFF)),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
            child: Column(children: [
              for (final item in footerItems)
                _SidebarTile(
                  item: item,
                  active: currentPath == item.path,
                  onTap: () => onNavigate(item.path),
                ),
              _SidebarTile(
                item: const _NavItem(
                    icon: Icons.logout_rounded, label: 'Sign Out', path: ''),
                active: false,
                onTap: onSignOut,
                isDestructive: true,
              ),
              const SizedBox(height: 12),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _SidebarBrand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.accentDashboard, AppColors.accentPcos],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentDashboard.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.home_rounded, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('HomeSync', style: AppTextStyles.titleMedium),
          Text('Smart Home Manager',
              style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
        ]),
      ]),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String label;
  const _GroupLabel(this.label);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
    child: Text(
      label.toUpperCase(),
      style: AppTextStyles.labelLarge.copyWith(
        color: AppColors.textSubtle,
        letterSpacing: 1.6,
      ),
    ),
  );
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
    final iconColor = isDestructive
        ? AppColors.statusOverdue.withValues(alpha: 0.7)
        : active
            ? AppColors.accentDashboard
            : AppColors.textMuted;
    final textColor = isDestructive
        ? AppColors.statusOverdue.withValues(alpha: 0.7)
        : active
            ? AppColors.textPrimary
            : AppColors.textMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: active
                ? AppColors.accentDashboard.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: active
                ? Border(
                    left: BorderSide(
                        color: AppColors.accentDashboard, width: 3))
                : null,
          ),
          child: Row(children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.accentDashboard.withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, size: 15, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.label,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: textColor,
                  fontWeight:
                      active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Bottom tab bar ─────────────────────────────────────────────
class _AuroraBottomBar extends StatelessWidget {
  final List<_NavItem> items;
  final List<_NavItem> moreItems;
  final String currentPath;
  final ValueChanged<String> onNavigate;

  const _AuroraBottomBar({
    required this.items,
    required this.moreItems,
    required this.currentPath,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xF70D0A1C),
        border: Border(top: BorderSide(color: AppColors.glassBorder)),
      ),
      child: SafeArea(
        top: false,
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
              moreItems: moreItems,
              onNavigate: onNavigate,
            ),
          ),
        ]),
      ),
    );
  }
}

class _BottomTab extends StatelessWidget {
  final _NavItem item;
  final bool active;
  final VoidCallback onTap;

  const _BottomTab({
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? AppColors.accentDashboard.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(
            item.icon,
            size: 20,
            color: active ? AppColors.accentDashboard : AppColors.textSubtle,
          ),
          if (active)
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentDashboard,
              ),
            ),
          Text(
            item.label,
            style: AppTextStyles.labelSmall.copyWith(
              color:
                  active ? AppColors.accentDashboard : AppColors.textSubtle,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ]),
      ),
    );
  }
}

class _MoreTab extends StatelessWidget {
  final List<_NavItem> moreItems;
  final ValueChanged<String> onNavigate;

  const _MoreTab({required this.moreItems, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showGlassSheet(
        context: context,
        title: 'More',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: moreItems
              .map((item) => ListTile(
                    leading: Icon(item.icon, color: AppColors.textMuted),
                    title: Text(
                      item.label,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textPrimary),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onNavigate(item.path);
                    },
                  ))
              .toList(),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.more_horiz_rounded,
              size: 20, color: AppColors.textSubtle),
          Text(
            'More',
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.textSubtle),
          ),
        ],
      ),
    );
  }
}

// ── Data classes ───────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label, path;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.path,
  });
}

class _NavGroup {
  final String label;
  final List<_NavItem> items;
  const _NavGroup({required this.label, required this.items});
}
