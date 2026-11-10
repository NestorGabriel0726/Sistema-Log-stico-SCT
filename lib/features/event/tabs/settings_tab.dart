import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/ui_bits.dart';
import '../../../data/providers.dart';
import '../../../domain/models.dart';
class SettingsTab extends ConsumerWidget {
  final TransportEvent event;
  const SettingsTab({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(localStoreProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Seção: permissões de check-in
        _SettingsSection(
          title: 'Permissões de check-in',
          icon: Icons.how_to_reg_outlined,
          children: [
            SwitchListTile(
              title: const Text('Capitão pode fazer check-in'),
              subtitle: const Text('Libera o perfil Capitão para registrar entrada/saída'),
              value: event.captainCheckinEnabled,
              onChanged: (v) =>
                  store.updateEvent(event.copyWith(captainCheckinEnabled: v)),
            ),
            Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            SwitchListTile(
              title: const Text('Ajudante do capitão pode fazer check-in'),
              subtitle: const Text('Libera o perfil Ajudante para registrar entrada/saída'),
              value: event.helperCheckinEnabled,
              onChanged: (v) =>
                  store.updateEvent(event.copyWith(helperCheckinEnabled: v)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Seção: dados de demonstração
        _SettingsSection(
          title: 'Dados de demonstração',
          icon: Icons.restore_outlined,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(Icons.restore_rounded,
                    size: 18, color: AppColors.danger),
              ),
              title: const Text('Restaurar dados de demonstração'),
              subtitle: const Text(
                  'Substitui todos os dados locais pelos dados de exemplo. Esta ação não pode ser desfeita.'),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () async {
                final ok = await confirmDialog(
                  context,
                  'Isso substitui todos os dados locais pelo exemplo. Seus eventos, passagens e histórico serão apagados.',
                  title: 'Restaurar demonstração',
                );
                if (ok && context.mounted) await store.resetDemo();
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.brand),
                const SizedBox(width: AppSpacing.sm),
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: AppColors.brand)),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          ...children,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// showVehicleSheet — bottom sheet de criação/edição de veículo com paradas
// ─────────────────────────────────────────────────────────────────────────────

