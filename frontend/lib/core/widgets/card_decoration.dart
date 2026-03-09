import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable card box decoration with shadow
class CardDecorations {
  /// Standard card decoration with white background and shadow
  static BoxDecoration cardDecoration({
    double borderRadius = 20,
    Color backgroundColor = Colors.white,
    double blurRadius = 10,
    Offset offset = const Offset(0, 4),
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: AppColors.cardShadow,
          blurRadius: blurRadius,
          offset: offset,
        ),
      ],
    );
  }

  /// Input field decoration
  static BoxDecoration inputDecoration({
    double borderRadius = 14,
    Color backgroundColor = Colors.white,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Subtle card decoration
  static BoxDecoration subtleCardDecoration({
    double borderRadius = 12,
    Color backgroundColor = Colors.white,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.2),
          spreadRadius: 2,
          blurRadius: 5,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}
