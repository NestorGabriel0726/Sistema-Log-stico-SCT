import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/connection_status_badge.dart';

/// Tela Principal - Histórico e Lista de Eventos da Congregação (Seção 72).
class EventsListPage extends StatelessWidget {
  const EventsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos de Transporte'),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: ConnectionStatusBadge(isConnected: true),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Exemplo de Card de Evento (Em conformidade com Seção 72)
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              onTap: () => context.go('/events/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                          ),
                          child: const Text(
                            'CONGRESSO REGIONAL',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                          ),
                          child: const Text(
                            'ABERTO',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Declare as Boas Novas! 2026',
                      style: AppTypography.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Row(
                      children: [
                        Icon(Icons.calendar_month_outlined, size: 16, color: AppColors.textSecondaryLight),
                        SizedBox(width: AppSpacing.xs),
                        Text(
                          '16/10/2026 a 18/10/2026 (3 dias)',
                          style: AppTypography.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.md),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.groups_outlined, size: 18, color: AppColors.primary),
                            SizedBox(width: AppSpacing.xs),
                            Text('6 passageiros inscritos', style: AppTypography.bodySmall),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.directions_bus_outlined, size: 18, color: AppColors.secondary),
                            SizedBox(width: AppSpacing.xs),
                            Text('3 veículos', style: AppTypography.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Apenas usuários autorizados (Coordenador)
        },
        icon: const Icon(Icons.add),
        label: const Text('Novo Evento'),
      ),
    );
  }
}
