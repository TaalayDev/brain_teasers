import 'package:flutter/material.dart';

enum ScreenSize {
  xxs(max: 375),
  xs(max: 575),
  sm(min: 576, max: 767),
  md(min: 768, max: 991),
  lg(min: 992, max: 1199),
  xl(min: 1200, max: double.infinity);

  final double? min;
  final double? max;

  const ScreenSize({this.min, required this.max});

  bool matches(double width) {
    if (min != null && width < min!) return false;
    if (max != null && width > max!) return false;
    return true;
  }

  static ScreenSize? forWidth(double width) {
    return values.cast<ScreenSize?>().firstWhere(
          (size) => size!.matches(width),
          orElse: () => null,
        );
  }
}

extension SizeExtensions on Size {
  R adaptiveValue<R>(
    R defValue,
    Map<ScreenSize, R> values, {
    double? customWidth,
  }) {
    final width = customWidth ?? this.width;
    final size = ScreenSize.forWidth(width);
    return values[size] ?? defValue;
  }
}

extension ContextExtensions on BuildContext {
  ScreenSize get screenSize => MediaQuery.of(this).size.adaptiveValue(
        ScreenSize.md,
        {
          ScreenSize.xxs: ScreenSize.xs,
          ScreenSize.xs: ScreenSize.sm,
          ScreenSize.sm: ScreenSize.md,
          ScreenSize.md: ScreenSize.lg,
          ScreenSize.lg: ScreenSize.xl,
        },
      );

  R byScreenSize<R>(
    R Function() defValue,
    Map<ScreenSize, R Function()> values,
  ) {
    return values[screenSize]?.call() ?? defValue();
  }
}
