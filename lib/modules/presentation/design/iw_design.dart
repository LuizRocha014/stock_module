import 'package:flutter/material.dart';

/// Tokens visuais compartilhados pelos módulos (cópia 1:1 do design system).
class IwColors {
  IwColors._();

  static const Color primary = Color(0xFF395E83);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFD3E4FF);
  static const Color onPrimaryContainer = Color(0xFF001D33);
  static const Color primaryDeep = Color(0xFF0E2238);
  static const Color primaryFixed = Color(0xFFC9E2FF);

  static const Color secondary = Color(0xFF535F70);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFD7E3F8);
  static const Color onSecondaryContainer = Color(0xFF101C2B);

  static const Color tertiary = Color(0xFF6B5778);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFF2DAFF);
  static const Color onTertiaryContainer = Color(0xFF251431);

  static const Color surface = Color(0xFFFDFCFF);
  static const Color surfaceDim = Color(0xFFDCDBE0);
  static const Color surfaceBright = Color(0xFFFDFCFF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF6F6FA);
  static const Color surfaceContainer = Color(0xFFF0F1F4);
  static const Color surfaceContainerHigh = Color(0xFFEAEBEF);
  static const Color surfaceContainerHighest = Color(0xFFE4E5E9);
  static const Color onSurface = Color(0xFF1A1C1E);
  static const Color onSurfaceVariant = Color(0xFF43474E);
  static const Color surfaceVariant = Color(0xFFDFE3EB);
  static const Color outline = Color(0xFF74777F);
  static const Color outlineVariant = Color(0xFFC4C6CF);

  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);

  static const Color success = Color(0xFF1F7A4D);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color successContainer = Color(0xFFB6F2C8);
  static const Color onSuccessContainer = Color(0xFF002111);

  static const Color warning = Color(0xFFB36500);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color warningContainer = Color(0xFFFFDDB4);
  static const Color onWarningContainer = Color(0xFF2C1700);

  static const Color accentOrange = Color(0xFFF58220);
  static const Color accentOrangeDeep = Color(0xFFD86A0F);
  static const Color accentSky = Color(0xFF1E8BEA);
  static const Color accentLeaf = Color(0xFF4DA64A);
}

class IwSpacing {
  IwSpacing._();
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s7 = 28;
  static const double s8 = 32;
  static const double s10 = 40;
  static const double s12 = 48;
}

class IwRadius {
  IwRadius._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 28;
}

class IwSizing {
  IwSizing._();
  static const double appBarHeight = 60;
  static const double contentMaxWidth = 1200;
}
