import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';

/// Tela inicial de Login via Google OAuth (Seções 12 e 13).
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _isSigningIn = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isSigningIn = true;
    });

    try {
      await ref.read(authNotifierProvider.notifier).signInWithGoogle();
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    final bool isLoading = _isSigningIn || authState is AuthStateLoadingProfile;
    String? errorMessage;
    if (authState is AuthStateRecoverableError) {
      errorMessage = authState.message;
    } else if (authState is AuthStateSessionExpired) {
      errorMessage = 'Sua sessão expirou. Faça login novamente com a Conta Google.';
    }

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.directions_bus_rounded,
                      size: 56,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Gestão de Transporte',
                      textAlign: TextAlign.center,
                      style: AppTypography.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Assembleias e Congressos',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    if (errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          errorMessage,
                          style: const TextStyle(color: AppColors.error, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    ElevatedButton.icon(
                      onPressed: isLoading ? null : _handleGoogleSignIn,
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.account_circle_outlined),
                      label: Text(isLoading ? 'Conectando...' : 'Entrar com Conta Google'),
                    ),

                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'O acesso é restrito aos membros designados e autorizados da congregação.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall,
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
