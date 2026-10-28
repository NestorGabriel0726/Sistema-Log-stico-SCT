import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_mode_provider.dart';
import '../../data/providers.dart';
import '../../domain/models.dart';

class WelcomePage extends ConsumerStatefulWidget {
  const WelcomePage({super.key});

  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage> {
  final _nameController = TextEditingController(text: 'Carlos Coordenador');
  UserRole _role = UserRole.coordinator;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _enter() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final store = ref.read(localStoreProvider);
    String? vehicleId;
    if (_role == UserRole.captain || _role == UserRole.captainHelper) {
      final vehicles = store.listEvents().isEmpty
          ? const <Vehicle>[]
          : store.vehiclesForEvent(store.listEvents().first.id);
      vehicleId = vehicles.isEmpty ? null : vehicles.first.id;
    }
    store.signIn(name: name, role: _role, assignedVehicleId: vehicleId);
  }

  String get _roleDescription => switch (_role) {
        UserRole.coordinator =>
          'Acesso completo: eventos, finanças, veículos, check-in e histórico.',
        UserRole.coordinatorHelper =>
          'Apoio operacional: passagens, listas e check-in. Sem excluir eventos.',
        UserRole.captain =>
          'Lista do seu ônibus e leitura dos demais. Check-in conforme permissão.',
        UserRole.captainHelper =>
          'Apoio ao capitão. Check-in apenas com permissão do coordenador.',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // Fundo estrutural
          Positioned.fill(
            child: Row(
              children: [
                // Painel esquerdo — identidade (visível apenas em telas largas)
                if (MediaQuery.of(context).size.width >= AppSpacing.breakpointTablet)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.canvasDark : AppColors.brand,
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius:
                                          BorderRadius.circular(AppSpacing.radiusSm),
                                    ),
                                    child: const Icon(Icons.directions_bus_rounded,
                                        color: Colors.white, size: 24),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    'Transporte SCT',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                'Gestão Logística\nde Transporte',
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                'Controle completo de passagens, veículos, passageiros, alocações e check-in — tudo em um único painel operacional.',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.82),
                                  height: 1.6,
                                ),
                              ),
                              const Spacer(),
                              Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.sm,
                                children: [
                                  _FeatureChip(
                                      icon: Icons.receipt_long_outlined,
                                      label: 'Passagens'),
                                  _FeatureChip(
                                      icon: Icons.directions_bus_outlined,
                                      label: 'Veículos'),
                                  _FeatureChip(
                                      icon: Icons.how_to_reg_outlined,
                                      label: 'Check-in'),
                                  _FeatureChip(
                                      icon: Icons.people_outline, label: 'Passageiros'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                // Painel direito — formulário
                Expanded(
                  child: Container(
                    color: isDark ? AppColors.canvasDark : AppColors.canvasLight,
                  ),
                ),
              ],
            ),
          ),
          // Formulário centralizado
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.lg,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppSpacing.narrowMaxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header mobile (quando painel esquerdo não aparece)
                      if (MediaQuery.of(context).size.width < AppSpacing.breakpointTablet) ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.brand,
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusSm),
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
                                    'Transporte SCT',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Gestão Logística',
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(color: cs.onSurfaceVariant),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            _ThemeModeButton(),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ] else ...[
                        // Apenas o botão de tema no canto superior
                        Align(
                          alignment: Alignment.topRight,
                          child: _ThemeModeButton(),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      // Card do formulário
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Identificação de acesso',
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Selecione seu perfil de acesso para continuar.',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            // Nome
                            Text('Seu nome', style: theme.textTheme.labelLarge),
                            const SizedBox(height: AppSpacing.sm),
                            TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                hintText: 'Como aparece para a equipe',
                                prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                              ),
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            // Perfil
                            Text('Perfil de acesso', style: theme.textTheme.labelLarge),
                            const SizedBox(height: AppSpacing.sm),
                            DropdownButtonFormField<UserRole>(
                              value: _role,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.shield_outlined, size: 20),
                              ),
                              items: UserRole.values
                                  .map((r) => DropdownMenuItem(
                                      value: r,
                                      child: Text(
                                        r.label,
                                        overflow: TextOverflow.ellipsis,
                                      )))
                                  .toList(),
                              onChanged: (v) => setState(() => _role = v ?? _role),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            // Descrição do perfil
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.surfaceElevatedDark
                                    : AppColors.canvasLight,
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd),
                                border: Border.all(
                                  color:
                                      isDark ? AppColors.borderDark : AppColors.borderLight,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 16,
                                    color: cs.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      _roleDescription,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                          color: cs.onSurfaceVariant),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            FilledButton.icon(
                              onPressed: _enter,
                              icon: const Icon(Icons.login_rounded, size: 18),
                              label: const Text('Entrar no painel'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeModeButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final icon = switch (mode) {
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
      ThemeMode.system => Icons.brightness_auto_outlined,
    };
    return IconButton(
      tooltip: 'Alternar tema',
      onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
      icon: Icon(icon, size: 20),
    );
  }
}
