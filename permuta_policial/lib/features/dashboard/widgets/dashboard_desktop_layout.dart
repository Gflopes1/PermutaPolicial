import 'package:flutter/material.dart';

/// Breakpoint para layout desktop/tablet landscape (2 colunas).
const double kDashboardDesktopBreakpoint = 900;

/// Centraliza conteúdo e aplica 2 colunas em telas largas.
class DashboardDesktopLayout extends StatelessWidget {
  final Widget leftColumn;
  final Widget rightColumn;
  final Widget mobileColumn;

  const DashboardDesktopLayout({
    super.key,
    required this.leftColumn,
    required this.rightColumn,
    required this.mobileColumn,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= kDashboardDesktopBreakpoint;

        if (!isWide) {
          return mobileColumn;
        }

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: leftColumn),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: rightColumn),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
