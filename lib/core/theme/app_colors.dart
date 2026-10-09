import 'package:flutter/material.dart';

/// Paleta de cores padronizada e moderna para o sistema.
/// Segue princípios de Material 3 com excelente contraste e legibilidade.
abstract class AppColors {
  // Cores Primárias (Identidade Visual Executiva / Logística)
  static const Color primary = Color(0xFF1E3A8A); // Deep Indigo
  static const Color primaryLight = Color(0xFF3B82F6); // Vibrant Blue
  static const Color primaryDark = Color(0xFF172554); // Midnight Blue

  // Cores Secundárias e Acentos
  static const Color secondary = Color(0xFF0D9488); // Teal
  static const Color secondaryLight = Color(0xFF14B8A6);
  static const Color secondaryDark = Color(0xFF115E59);

  // Estados Operacionais (Semáforo Operacional)
  static const Color success = Color(0xFF16A34A); // Verde Esmeralda (Vaga liberada, Pago, Check-in ok)
  static const Color warning = Color(0xFFEAB308); // Amarelo Âmbar (Relocado, Parcialmente pago, Atenção)
  static const Color error = Color(0xFFDC2626); // Vermelho Rubi (Lotado, Desistente, Pendente crítico)
  static const Color info = Color(0xFF0284C7); // Azul Celeste (Informativo, Snapshot)

  // Neutros e Superfícies (Modo Claro)
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0); // Slate 200
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate 900
  static const Color textSecondaryLight = Color(0xFF475569); // Slate 600
  static const Color textMutedLight = Color(0xFF94A3B8); // Slate 400

  // Neutros e Superfícies (Modo Escuro)
  static const Color backgroundDark = Color(0xFF0B0F19);
  static const Color surfaceDark = Color(0xFF111827);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color borderDark = Color(0xFF334155);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFFCBD5E1);
  static const Color textMutedDark = Color(0xFF64748B);
}
