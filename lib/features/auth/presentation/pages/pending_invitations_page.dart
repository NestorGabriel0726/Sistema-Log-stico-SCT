import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../invitations/domain/entities/invitation.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';

/// Tela exibida quando o usuário possui convites pendentes de aceite (Seção 13).
class PendingInvitationsPage extends ConsumerStatefulWidget {
  const PendingInvitationsPage({super.key});

  @override
  ConsumerState<PendingInvitationsPage> createState() => _PendingInvitationsPageState();
}

class _PendingInvitationsPageState extends ConsumerState<PendingInvitationsPage> {
  String? _acceptingInvitationId;

  Future<void> _handleAccept(String invitationId) async {
    setState(() {
      _acceptingInvitationId = invitationId;
    });

    try {
      await ref.read(authNotifierProvider.notifier).acceptInvitation(invitationId);
    } finally {
      if (mounted) {
        setState(() {
          _acceptingInvitationId = null;
        });
      }
    }
  }

  Future<void> _handleSignOut() async {
    await ref.read(authNotifierProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    List<Invitation> invitations = const [];
    String userEmail = '';

    if (authState is AuthStateHasPendingInvitations) {
      invitations = authState.invitations;
      userEmail = authState.profile.email;
    } else if (authState is AuthStateAuthorized) {
      invitations = const [];
      userEmail = authState.profile.email;
    }

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Convites Pendentes'),
        actions: [
          IconButton(
            tooltip: 'Recarregar convites',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(authNotifierProvider.notifier).refreshUserStatus(),
          ),
          IconButton(
            tooltip: 'Sair da Conta',
            icon: const Icon(Icons.logout_rounded),
            onPressed: _handleSignOut,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
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
                          Icons.mail_outline_rounded,
                          size: 48,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Text(
                          'Convites Recebidos',
                          style: AppTypography.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Conectado como: $userEmail',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Text(
                          'Você foi convidado para participar da gestão logística das congregações abaixo. Aceite o convite correspondente para acessar o sistema.',
                          style: AppTypography.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (invitations.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        children: [
                          const Icon(Icons.inbox_outlined, size: 40, color: AppColors.textMutedLight),
                          const SizedBox(height: AppSpacing.sm),
                          const Text(
                            'Nenhum convite pendente no momento.',
                            style: AppTypography.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          OutlinedButton.icon(
                            onPressed: () => ref.read(authNotifierProvider.notifier).refreshUserStatus(),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Verificar novamente'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...invitations.map((invitation) {
                    final isAccepting = _acceptingInvitationId == invitation.id;
                    final isExpired = invitation.isExpired;

                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        invitation.congregationName,
                                        style: AppTypography.titleMedium,
                                      ),
                                      if (invitation.eventTheme != null) ...[
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          'Evento: ${invitation.eventTheme}',
                                          style: AppTypography.bodyMedium.copyWith(
                                            color: AppColors.primaryLight,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: AppSpacing.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                    border: Border.all(
                                      color: AppColors.secondary.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    invitation.roleDisplay,
                                    style: const TextStyle(
                                      color: AppColors.secondaryDark,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (invitation.vehicleName != null) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Row(
                                children: [
                                  const Icon(Icons.directions_bus_outlined, size: 16, color: AppColors.textSecondaryLight),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    'Veículo designado: ${invitation.vehicleName}',
                                    style: AppTypography.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  size: 16,
                                  color: isExpired ? AppColors.error : AppColors.textMutedLight,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  isExpired
                                      ? 'Expirado em: ${dateFormat.format(invitation.expiresAt)}'
                                      : 'Expira em: ${dateFormat.format(invitation.expiresAt)}',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: isExpired ? AppColors.error : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: isExpired || isAccepting ? null : () => _handleAccept(invitation.id),
                                icon: isAccepting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.check_circle_outline_rounded, size: 18),
                                label: Text(
                                  isAccepting
                                      ? 'Aceitando...'
                                      : isExpired
                                          ? 'Convite Expirado'
                                          : 'Aceitar Convite',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: TextButton.icon(
                    onPressed: _handleSignOut,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Entrar com outra conta'),
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
