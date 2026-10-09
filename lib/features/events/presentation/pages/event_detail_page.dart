import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/connection_status_badge.dart';

/// Tela do Evento - Dashboard Operacional e Abas de Gestão (Seções 73 e 74).
class EventDetailPage extends StatefulWidget {
  final String eventId;

  const EventDetailPage({
    super.key,
    required this.eventId,
  });

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Declare as Boas Novas! 2026', style: AppTypography.titleMedium),
            Text('Congresso Regional • 16/10 a 18/10', style: AppTypography.bodySmall),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: ConnectionStatusBadge(isConnected: true),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Dashboard'),
            Tab(icon: Icon(Icons.directions_bus_outlined), text: 'Veículos'),
            Tab(icon: Icon(Icons.people_outline), text: 'Passageiros'),
            Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Passagens'),
            Tab(icon: Icon(Icons.fact_check_outlined), text: 'Check-in'),
            Tab(icon: Icon(Icons.notifications_none_outlined), text: 'Notificações'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          _buildPlaceholderTab('Veículos e Lotação Diária (Seção 77)'),
          _buildPlaceholderTab('Lista de Passageiros (Seção 76)'),
          _buildPlaceholderTab('Gestão de Passagens e Pagamentos (Seção 75)'),
          _buildPlaceholderTab('Check-in Diário - Ida e Volta (Seção 80)'),
          _buildPlaceholderTab('Centro de Notificações em Tempo Real (Seção 81)'),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Painel Financeiro (Restrito aos Coordenadores - Seção 74 e 118)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.monetization_on_outlined, color: AppColors.primary),
                    SizedBox(width: AppSpacing.xs),
                    Text('Resumo Financeiro (Visão Administrativa)', style: AppTypography.titleSmall),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Total Esperado',
                        value: 'R\$ 250,00',
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Recebido',
                        value: 'R\$ 200,00',
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Pendente',
                        value: 'R\$ 50,00',
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Lotação dos Veículos por Dia (Seção 74)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.directions_bus, color: AppColors.secondary),
                    SizedBox(width: AppSpacing.xs),
                    Text('Lotação Operacional por Dia', style: AppTypography.titleSmall),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _buildVehicleCapacityRow('Ônibus 01', 'Sexta-feira', 2, 30),
                const Divider(),
                _buildVehicleCapacityRow('Ônibus 02', 'Sexta-feira', 1, 32),
                const Divider(),
                _buildVehicleCapacityRow('Ônibus 01', 'Domingo', 1, 30),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({required String title, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCapacityRow(String vehicleName, String dayLabel, int active, int capacity) {
    final double ratio = active / capacity;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vehicleName, style: AppTypography.labelLarge),
                Text(dayLabel, style: AppTypography.bodySmall),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              child: LinearProgressIndicator(
                value: ratio,
                backgroundColor: AppColors.borderLight,
                color: ratio >= 1.0 ? AppColors.error : AppColors.primary,
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            '$active/$capacity',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderTab(String title) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.handyman_outlined, size: 48, color: AppColors.textMutedLight),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppTypography.titleSmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
