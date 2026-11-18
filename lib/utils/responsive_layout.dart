import 'package:flutter/material.dart';

class ResponsiveLayout {
  /// Returns screen width
  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;

  /// Returns screen height
  static double height(BuildContext context) => MediaQuery.sizeOf(context).height;

  /// Checks if screen is small/compact (< 375dp)
  static bool isCompact(BuildContext context) => width(context) < 375;

  /// Checks if screen is standard (375dp - 430dp)
  static bool isStandard(BuildContext context) => width(context) >= 375 && width(context) < 600;

  /// Checks if tablet or fold unfolded (>= 600dp)
  static bool isTablet(BuildContext context) => width(context) >= 600;

  /// Clamped horizontal padding based on screen width
  static double horizontalPadding(BuildContext context) {
    final w = width(context);
    return (w * 0.045).clamp(12.0, 24.0);
  }

  /// Clamped vertical padding based on screen height
  static double verticalPadding(BuildContext context) {
    final h = height(context);
    return (h * 0.02).clamp(10.0, 20.0);
  }

  /// Dynamic scale factor for fonts and icons
  static double scale(BuildContext context, double baseSize) {
    final w = width(context);
    // Baseline is 390dp (standard modern phone)
    final factor = (w / 390.0).clamp(0.85, 1.25);
    return baseSize * factor;
  }

  /// Dynamically sized Cyber-Cat HUD Orb diameter
  static double orbSize(BuildContext context) {
    final w = width(context);
    final h = height(context);
    final minDim = w < h ? w : h;
    return (minDim * 0.38).clamp(130.0, 220.0);
  }

  /// Page padding helper
  static EdgeInsets pagePadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: horizontalPadding(context),
      vertical: verticalPadding(context),
    );
  }

  /// Standard Adaptive Screen Wrapper with zero RenderFlex overflow guarantee
  static Widget screenScaffold({
    required BuildContext context,
    Widget? child,
    Widget? body,
    PreferredSizeWidget? appBar,
    Widget? drawer,
    Widget? bottomNavigationBar,
    Widget? floatingActionButton,
    FloatingActionButtonLocation? floatingActionButtonLocation,
    Color? backgroundColor,
    bool scrollable = false,
    EdgeInsetsGeometry? padding,
  }) {
    final contentWidget = body ?? child ?? const SizedBox.shrink();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      drawer: drawer,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            Widget content = Container(
              width: double.infinity,
              padding: padding,
              child: contentWidget,
            );

            if (scrollable) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: content,
                ),
              );
            }
            return content;
          },
        ),
      ),
    );
  }
}
