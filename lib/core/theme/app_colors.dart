import 'package:flutter/material.dart';

/// Paleta central do SCT — neutra, profissional, sem excessos decorativos.
abstract class AppColors {
  // ─── Marca ───────────────────────────────────────────────────────────────
  /// Azul-petróleo sobrio — cor primária
  static const brand = Color(0xFF1A6FBF);
  static const brandDark = Color(0xFF155DA0);
  static const brandLight = Color(0xFF3B8FD6);
  static const brandSubtle = Color(0xFFEBF4FB);

  // ─── Modo claro ───────────────────────────────────────────────────────────
  static const canvasLight = Color(0xFFF5F7FA);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceElevated = Color(0xFFF0F4F8);
  static const borderLight = Color(0xFFE2E8EF);
  static const borderMuted = Color(0xFFEDF1F5);
  static const textPrimaryLight = Color(0xFF0F1B2D);
  static const textSecondaryLight = Color(0xFF5A6A7E);
  static const textMutedLight = Color(0xFF93A1B0);

  // ─── Modo escuro ──────────────────────────────────────────────────────────
  static const canvasDark = Color(0xFF0E1521);
  static const surfaceDark = Color(0xFF162032);
  static const surfaceElevatedDark = Color(0xFF1E2D44);
  static const borderDark = Color(0xFF253347);
  static const borderMutedDark = Color(0xFF1C2B3E);
  static const textPrimaryDark = Color(0xFFE8EFF8);
  static const textSecondaryDark = Color(0xFF8BA3BE);
  static const textMutedDark = Color(0xFF4E6180);

  // ─── Semânticas (compartilhadas) ─────────────────────────────────────────
  static const success = Color(0xFF1A8A4A);
  static const successBg = Color(0xFFE8F7EE);
  static const successBgDark = Color(0xFF0D2E1A);

  static const warning = Color(0xFFBF7A10);
  static const warningBg = Color(0xFFFBF3E3);
  static const warningBgDark = Color(0xFF2D1E05);

  static const danger = Color(0xFFBF2828);
  static const dangerBg = Color(0xFFFAECEC);
  static const dangerBgDark = Color(0xFF2D0B0B);

  static const info = Color(0xFF1761A0);
  static const infoBg = Color(0xFFE7F1FA);
  static const infoBgDark = Color(0xFF0A1E35);

  // ─── Atalhos para código legado (mapeados para nova paleta) ───────────────
  static const primary = brand;
  static const error = danger;
  static const canvas = canvasLight;
  static const surface = surfaceLight;
  static const border = borderLight;
  static const textPrimary = textPrimaryLight;
  static const textSecondary = textSecondaryLight;
  static const accent = Color(0xFF1A7A70);
}
