import 'package:flutter/material.dart';

/// Sistema de espaçamentos e raios de borda padronizados.
abstract class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Bordas arredondadas (Border Radius)
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusFull = 999.0;

  // EdgeInsets comuns
  static const EdgeInsets paddingScreenMobile = EdgeInsets.all(md);
  static const EdgeInsets paddingScreenDesktop = EdgeInsets.symmetric(horizontal: xl, vertical: lg);
  static const EdgeInsets paddingCard = EdgeInsets.all(md);
  static const EdgeInsets paddingItem = EdgeInsets.symmetric(horizontal: md, vertical: sm);
}
