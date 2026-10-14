import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                      gradient: const LinearGradient(
                        colors: [AppColors.brand, AppColors.brandDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 40),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Transporte SCT',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Quadro branco digital da congregação: passagens, ônibus e imprevistos de última hora.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Seu nome', style: theme.textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(hintText: 'Como aparece para a equipe'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Perfil de acesso', style: theme.textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<UserRole>(
                    initialValue: _role,
                    items: UserRole.values
                        .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                        .toList(),
                    onChanged: (v) => setState(() => _role = v ?? _role),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    switch (_role) {
                      UserRole.coordinator =>
                        'Controle total: eventos, finanças, veículos, histórico e check-in.',
                      UserRole.coordinatorHelper =>
                        'Apoio operacional: passagens, listas e check-in. Sem excluir o evento.',
                      UserRole.captain =>
                        'Lista do seu ônibus, leitura dos demais. Check-in se o coordenador liberar.',
                      UserRole.captainHelper =>
                        'Apoio ao capitão. Check-in só com o toggle do coordenador.',
                    },
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(onPressed: _enter, child: const Text('Entrar no painel')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
