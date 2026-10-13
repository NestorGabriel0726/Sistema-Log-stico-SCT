import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../domain/entities/congregation.dart';

/// Tela para seleção da congregação ativa quando o usuário possui vínculo com mais de uma (Seção 5 e 13).
class SelectCongregationPage extends ConsumerWidget {
  const SelectCongregationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    List<Congregation> congregations = const [];
    if (authState is AuthStateSelectCongregation) {
      congregations = authState.congregations;
    } else if (authState is AuthStateAuthorized) {
      congregations = authState.allCongregations;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Congregação'),
        actions: [
          IconButton(
            tooltip: 'Sair da Conta',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.apartment_rounded,
                          size: 48,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Text(
                          'Escolha a Congregação',
                          style: AppTypography.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        const Text(
                          'Seu usuário possui vínculo ativo com múltiplas congregações. Selecione qual congregação deseja gerenciar neste momento.',
                          style: AppTypography.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ...congregations.map((congregation) {
                  final roleName = memberRoleDisplayName(
                    congregation.currentUserRole ?? MemberRole.member,
                  );

                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      onTap: () {
                        ref
                            .read(authNotifierProvider.notifier)
                            .selectCongregation(congregation);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.location_city_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    congregation.name,
                                    style: AppTypography.titleMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${congregation.city} - ${congregation.state}',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              ),
                              child: Text(
                                roleName,
                                style: const TextStyle(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textMutedLight,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: TextButton.icon(
                    onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sair da Conta'),
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
