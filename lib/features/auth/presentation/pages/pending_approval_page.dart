import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/network/supabase_service.dart';

/// Tela exibida quando o usuário loga com Google mas ainda não possui convite ou congregação vinculada (Seção 13).
class PendingApprovalPage extends StatelessWidget {
  const PendingApprovalPage({super.key});

  Future<void> _handleSignOut(BuildContext context) async {
    await SupabaseService.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final email = SupabaseService.currentUserEmail ?? 'Usuário';

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.hourglass_empty_rounded,
                      size: 64,
                      color: AppColors.warning,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Acesso Aguardando Autorização',
                      textAlign: TextAlign.center,
                      style: AppTypography.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Você entrou com a conta:\n$email',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Sua autenticação foi realizada com sucesso, porém você ainda não possui convite aceito ou vínculo ativo com uma congregação neste sistema.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Por favor, solicite ao Coordenador do Evento que envie o convite para o seu endereço de e-mail.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    OutlinedButton.icon(
                      onPressed: () => _handleSignOut(context),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Sair da Conta'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
