/// Sistema de espaçamento baseado em múltiplos de 4px.
/// Toda dimensão no app deve usar um desses valores ou composições deles.
abstract class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  // Raios de borda
  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusFull = 999;

  // Larguras de layout
  static const double contentMaxWidth = 1280;
  static const double formMaxWidth = 720;
  static const double narrowMaxWidth = 480;

  // Breakpoints
  static const double breakpointMobile = 600;
  static const double breakpointTablet = 1024;

  // Sidebar
  static const double sidebarWidth = 240;
  static const double sidebarCollapsedWidth = 72;
}
