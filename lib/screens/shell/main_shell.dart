import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../services/auth_service.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _selectedIndex = 0;
  List<_NavItem> _activeNavItems = _baseNavItems;

  static const List<_NavItem> _baseNavItems = [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard', path: '/'),
    _NavItem(icon: Icons.cleaning_services_rounded, label: 'Cleaning', path: '/cleaning'),
    _NavItem(icon: Icons.shopping_cart_rounded, label: 'Shopping', path: '/shopping'),
    _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Budget', path: '/budget'),
    _NavItem(icon: Icons.receipt_long_rounded, label: 'Expenses', path: '/expenses'),
    _NavItem(icon: Icons.favorite_rounded, label: 'Health', path: '/health'),
    _NavItem(icon: Icons.restaurant_menu_rounded, label: 'Food', path: '/food'),
    _NavItem(icon: Icons.auto_awesome_rounded, label: 'AI Advisor', path: '/advisor'),
  ];

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
    context.go(_activeNavItems[index].path);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 800;
    final isExpanded = width >= 1200;

    final wishItem = _NavItem(
      icon: Icons.favorite_border_rounded,
      label: isAdmin ? "Wife's Wish List" : 'Wish List',
      path: '/wishlist',
    );
    final navItems = [
      ..._baseNavItems.take(7),
      wishItem,
      _baseNavItems.last,
      if (isAdmin)
        const _NavItem(
          icon: Icons.health_and_safety_rounded,
          label: 'PCOS Guide',
          path: '/pcos-guide',
        ),
    ];
    _activeNavItems = navItems;

    // Sync index from current route
    final currentPath = GoRouterState.of(context).uri.path;
    final routeIndex = navItems.indexWhere((n) => n.path == currentPath);
    if (routeIndex != -1 && routeIndex != _selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedIndex = routeIndex);
      });
    }

    return Scaffold(
      // ── Mobile AppBar ──────────────────────────────────────────
      appBar: isWide
          ? null
          : AppBar(
              titleSpacing: 0,
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryPurple, AppTheme.accentTeal],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.home_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'HomeSync',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              actions: [
                const _AdminBadge(),
                IconButton(
                  icon: Icon(isDark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded),
                  onPressed: () =>
                      ref.read(themeModeProvider.notifier).state = !isDark,
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  tooltip: 'Notification Settings',
                  onPressed: () => context.push('/settings'),
                ),
                const SizedBox(width: 4),
              ],
            ),

      // ── Mobile Drawer ──────────────────────────────────────────
      drawer: isWide
          ? null
          : _MobileDrawer(
              selectedIndex: _selectedIndex,
              navItems: navItems,
              isDark: isDark,
              isAdmin: isAdmin,
              shellContext: context,
              onTap: (i) {
                Navigator.pop(context);
                _onNavTap(i);
              },
              onToggleTheme: () =>
                  ref.read(themeModeProvider.notifier).state = !isDark,
              onSignOut: () {
                Navigator.pop(context);
                ref.read(authServiceProvider).signOut();
              },
            ),

      // ── Body ───────────────────────────────────────────────────
      body: isWide
          ? Row(
              children: [
                _SideNavRail(
                  selectedIndex: _selectedIndex,
                  navItems: navItems,
                  onTap: _onNavTap,
                  isExpanded: isExpanded,
                  isDark: isDark,
                  onToggleTheme: () =>
                      ref.read(themeModeProvider.notifier).state = !isDark,
                  onSignOut: () => ref.read(authServiceProvider).signOut(),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: widget.child),
              ],
            )
          : widget.child,
    );
  }
}

// ─── Mobile Drawer ────────────────────────────────────────────────

class _MobileDrawer extends StatelessWidget {
  final int selectedIndex;
  final List<_NavItem> navItems;
  final bool isDark;
  final bool isAdmin;
  final ValueChanged<int> onTap;
  final VoidCallback onToggleTheme;
  final VoidCallback onSignOut;
  final BuildContext shellContext;

  const _MobileDrawer({
    required this.selectedIndex,
    required this.navItems,
    required this.isDark,
    required this.isAdmin,
    required this.onTap,
    required this.onToggleTheme,
    required this.onSignOut,
    required this.shellContext,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // ── Drawer header ──────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryPurple, AppTheme.accentTeal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.home_rounded,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'HomeSync',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Smart Home Manager',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 12,
                        ),
                      ),
                      if (isAdmin) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'ADMIN',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // ── Nav items ──────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                itemCount: navItems.length,
                itemBuilder: (ctx, i) {
                  final item = navItems[i];
                  final selected = selectedIndex == i;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: _DrawerNavTile(
                      item: item,
                      selected: selected,
                      onTap: () => onTap(i),
                    ),
                  );
                },
              ),
            ),

            // ── Footer actions ─────────────────────────────────
            Divider(
                height: 1, color: cs.onSurface.withOpacity(0.08)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: _FooterButton(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                onTap: () {
                  Navigator.pop(context);
                  shellContext.push('/settings');
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _FooterButton(
                      icon: isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      label: isDark ? 'Light Mode' : 'Dark Mode',
                      onTap: onToggleTheme,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FooterButton(
                      icon: Icons.logout_rounded,
                      label: 'Sign Out',
                      onTap: onSignOut,
                      isDestructive: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DrawerNavTile extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerNavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryPurple.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.primaryPurple.withOpacity(0.15)
                    : cs.onSurface.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.icon,
                color: selected
                    ? AppTheme.primaryPurple
                    : cs.onSurface.withOpacity(0.45),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              item.label,
              style: GoogleFonts.inter(
                color: selected
                    ? AppTheme.primaryPurple
                    : cs.onSurface.withOpacity(0.75),
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w400,
                fontSize: 14,
              ),
            ),
            if (selected) ...[
              const Spacer(),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _FooterButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = isDestructive ? Colors.red : cs.onSurface.withOpacity(0.6);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withOpacity(0.06)
              : cs.onSurface.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Wide Side Rail (unchanged) ───────────────────────────────────

class _SideNavRail extends StatelessWidget {
  final int selectedIndex;
  final List<_NavItem> navItems;
  final ValueChanged<int> onTap;
  final bool isExpanded;
  final bool isDark;
  final VoidCallback onToggleTheme;
  final VoidCallback onSignOut;

  const _SideNavRail({
    required this.selectedIndex,
    required this.navItems,
    required this.onTap,
    required this.isExpanded,
    required this.isDark,
    required this.onToggleTheme,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: isExpanded ? 220 : 72,
      color: cs.surface,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            if (isExpanded) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.primaryPurple,
                            AppTheme.accentTeal
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.home_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'HomeSync',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ] else ...[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryPurple, AppTheme.accentTeal],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.home_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(height: 24),
            ],
            Expanded(
              child: ListView.builder(
                itemCount: navItems.length,
                padding: EdgeInsets.symmetric(
                    horizontal: isExpanded ? 12 : 8),
                itemBuilder: (ctx, i) {
                  final item = navItems[i];
                  final selected = selectedIndex == i;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: isExpanded
                        ? _ExpandedNavTile(
                            item: item,
                            selected: selected,
                            onTap: () => onTap(i),
                          )
                        : _CompactNavTile(
                            item: item,
                            selected: selected,
                            onTap: () => onTap(i),
                          ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: IconButton(
                icon: Icon(isDark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded),
                onPressed: onToggleTheme,
                color: cs.onSurface.withOpacity(0.6),
                tooltip: isDark ? 'Light mode' : 'Dark mode',
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: IconButton(
                icon: const Icon(Icons.logout_rounded),
                onPressed: onSignOut,
                color: cs.onSurface.withOpacity(0.6),
                tooltip: 'Sign out',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandedNavTile extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _ExpandedNavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryPurple.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              color: selected
                  ? AppTheme.primaryPurple
                  : cs.onSurface.withOpacity(0.5),
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              item.label,
              style: GoogleFonts.inter(
                color: selected
                    ? AppTheme.primaryPurple
                    : cs.onSurface.withOpacity(0.6),
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactNavTile extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _CompactNavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primaryPurple.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            item.icon,
            color: selected
                ? AppTheme.primaryPurple
                : cs.onSurface.withOpacity(0.5),
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String path;
  const _NavItem(
      {required this.icon, required this.label, required this.path});
}

class _AdminBadge extends ConsumerWidget {
  const _AdminBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    if (!isAdmin) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primaryPurple, AppTheme.accentTeal],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'ADMIN',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}
