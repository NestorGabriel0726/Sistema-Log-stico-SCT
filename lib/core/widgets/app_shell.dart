import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_mode_provider.dart';
import '../../data/providers.dart';

/// Scaffold adaptativo: NavigationRail em desktop/tablet, BottomNavigationBar em mobile.
/// Usado como wrapper raiz para as páginas com navegação principal.
class AppShell extends ConsumerWidget {
  final Widget child;
  final int selectedIndex;
  final List<_NavItem> navItems;
  final String? pageTitle;
  final List<Widget>? actions;
  final Widget? fab;

  const AppShell({
    super.key,
    required this.child,
    required this.selectedIndex,
    required this.navItems,
    this.pageTitle,
    this.actions,
    this.fab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= AppSpacing.breakpointTablet;
    final isTablet = width >= AppSpacing.breakpointMobile && width < AppSpacing.breakpointTablet;

    if (isDesktop || isTablet) {
      return _DesktopShell(
        selectedIndex: selectedIndex,
        navItems: navItems,
        pageTitle: pageTitle,
        actions: actions,
        fab: fab,
        compact: isTablet,
        child: child,
      );
    }

    return _MobileShell(
      selectedIndex: selectedIndex,
      navItems: navItems,
      pageTitle: pageTitle,
      actions: actions,
      fab: fab,
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Desktop shell
// ─────────────────────────────────────────────────────────────────────────────

class _DesktopShell extends ConsumerWidget {
  final Widget child;
  final int selectedIndex;
  final List<_NavItem> navItems;
  final String? pageTitle;
  final List<Widget>? actions;
  final Widget? fab;
  final bool compact;

  const _DesktopShell({
    required this.child,
    required this.selectedIndex,
    required this.navItems,
    this.pageTitle,
    this.actions,
    this.fab,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final store = ref.watch(localStoreProvider);
    final user = store.user;

    return Scaffold(
      body: Row(
        children: [
          // ─── Sidebar ───────────────────────────────────────────────────
          Container(
            width: compact ? AppSpacing.sidebarCollapsedWidth : AppSpacing.sidebarWidth,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              border: Border(
                right: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Logo / identidade
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? AppSpacing.sm : AppSpacing.md,
                      vertical: AppSpacing.lg,
                    ),
                    child: compact
                        ? const Icon(Icons.directions_bus_rounded,
                            color: AppColors.brand, size: 28)
                        : Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.brand,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                ),
                                child: const Icon(Icons.directions_bus_rounded,
                                    color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'SCT',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            color: AppColors.brand,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    Text(
                                      'Transporte',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: isDark
                                                ? AppColors.textSecondaryDark
                                                : AppColors.textSecondaryLight,
                                            fontSize: 10,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                  // Nav items
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? AppSpacing.xs : AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      children: navItems.asMap().entries.map((entry) {
                        final i = entry.key;
                        final item = entry.value;
                        final isSelected = i == selectedIndex;
                        return _SidebarItem(
                          item: item,
                          selected: isSelected,
                          compact: compact,
                          onTap: item.onTap,
                        );
                      }).toList(),
                    ),
                  ),
                  // Rodapé: usuário + tema
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? AppSpacing.xs : AppSpacing.sm,
                      vertical: AppSpacing.md,
                    ),
                    child: Column(
                      children: [
                        _ThemeToggleButton(compact: compact),
                        const SizedBox(height: AppSpacing.sm),
                        if (user != null)
                          _UserFooterTile(user: user, compact: compact, ref: ref),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ─── Conteúdo principal ────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Topbar
                _TopBar(
                  title: pageTitle,
                  actions: actions,
                  isDark: isDark,
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: fab,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile shell
// ─────────────────────────────────────────────────────────────────────────────

class _MobileShell extends ConsumerWidget {
  final Widget child;
  final int selectedIndex;
  final List<_NavItem> navItems;
  final String? pageTitle;
  final List<Widget>? actions;
  final Widget? fab;

  const _MobileShell({
    required this.child,
    required this.selectedIndex,
    required this.navItems,
    this.pageTitle,
    this.actions,
    this.fab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: pageTitle != null
          ? AppBar(
              title: Text(pageTitle!),
              actions: [
                ...(actions ?? []),
                _ThemeToggleIconButton(),
              ],
            )
          : null,
      body: child,
      floatingActionButton: fab,
      bottomNavigationBar: navItems.length > 1
          ? NavigationBar(
              selectedIndex: selectedIndex,
              destinations: navItems
                  .map((item) => NavigationDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.selectedIcon ?? item.icon),
                        label: item.label,
                        tooltip: item.label,
                      ))
                  .toList(),
              onDestinationSelected: (i) => navItems[i].onTap(),
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subcomponentes internos
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String? title;
  final List<Widget>? actions;
  final bool isDark;

  const _TopBar({this.title, this.actions, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (title != null)
            Expanded(
              child: Text(
                title!,
                style: Theme.of(context).textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            const Spacer(),
          ...(actions ?? []),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.item,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: compact ? item.label : '',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? AppSpacing.sm : AppSpacing.md,
              vertical: compact ? AppSpacing.sm : 10,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.brand.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: compact
                ? Center(
                    child: Icon(
                      selected ? (item.selectedIcon ?? item.icon) : item.icon,
                      size: 22,
                      color: selected
                          ? AppColors.brand
                          : (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight),
                    ),
                  )
                : Row(
                    children: [
                      Icon(
                        selected ? (item.selectedIcon ?? item.icon) : item.icon,
                        size: 20,
                        color: selected
                            ? AppColors.brand
                            : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          item.label,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight:
                                    selected ? FontWeight.w600 : FontWeight.w500,
                                color: selected
                                    ? AppColors.brand
                                    : (isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight),
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _ThemeToggleButton extends ConsumerWidget {
  final bool compact;
  const _ThemeToggleButton({required this.compact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final icon = switch (mode) {
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
      ThemeMode.system => Icons.brightness_auto_outlined,
    };
    final label = switch (mode) {
      ThemeMode.light => 'Claro',
      ThemeMode.dark => 'Escuro',
      ThemeMode.system => 'Automático',
    };
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (compact) {
      return Tooltip(
        message: 'Tema: $label',
        child: IconButton(
          onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
          icon: Icon(icon, size: 20),
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => ref.read(themeModeProvider.notifier).toggle(),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Tema: $label',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeToggleIconButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final icon = switch (mode) {
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
      ThemeMode.system => Icons.brightness_auto_outlined,
    };
    final label = switch (mode) {
      ThemeMode.light => 'Claro',
      ThemeMode.dark => 'Escuro',
      ThemeMode.system => 'Automático',
    };
    return IconButton(
      tooltip: 'Tema: $label',
      onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
      icon: Icon(icon),
    );
  }
}

class _UserFooterTile extends StatelessWidget {
  final dynamic user;
  final bool compact;
  final WidgetRef ref;

  const _UserFooterTile({required this.user, required this.compact, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initials =
        (user.name as String).isNotEmpty ? (user.name as String)[0].toUpperCase() : '?';

    if (compact) {
      return Tooltip(
        message: '${user.name} — ${user.role.label}\nSair',
        child: GestureDetector(
          onTap: () => ref.read(localStoreProvider).signOut(),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.brand.withValues(alpha: 0.12),
            child: Text(
              initials,
              style: const TextStyle(
                  color: AppColors.brand, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceElevatedDark
            : AppColors.canvasLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.brand.withValues(alpha: 0.12),
            child: Text(
              initials,
              style: const TextStyle(
                  color: AppColors.brand, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name as String,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  user.role.label as String,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        fontSize: 10,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'Sair',
            child: IconButton(
              onPressed: () => ref.read(localStoreProvider).signOut(),
              icon: const Icon(Icons.logout_outlined, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NavItem — definição de item de navegação
// ─────────────────────────────────────────────────────────────────────────────

class _NavItem {
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    this.selectedIcon,
    required this.onTap,
  });
}

/// Utilitário para criar um AppShell pré-configurado para a área de eventos.
AppShell buildEventShell({
  required BuildContext context,
  required WidgetRef ref,
  required Widget child,
  required String? pageTitle,
  required List<Widget>? actions,
  Widget? fab,
}) {
  return AppShell(
    selectedIndex: 0,
    navItems: [
      _NavItem(
        label: 'Eventos',
        icon: Icons.event_outlined,
        selectedIcon: Icons.event_rounded,
        onTap: () => context.go('/events'),
      ),
    ],
    pageTitle: pageTitle,
    actions: actions,
    fab: fab,
    child: child,
  );
}
