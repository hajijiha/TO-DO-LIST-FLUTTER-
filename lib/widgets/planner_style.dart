import 'package:flutter/material.dart';

const plannerBackground = Color(0xFFF6F5EF);
const plannerTeal = Color(0xFF174D4B);
const plannerMuted = Color(0xFF687971);
const plannerSurface = Color(0xFFFFFEFA);
const plannerBorder = Color(0xFFE1E6DC);

class PlannerPanel extends StatelessWidget {
  const PlannerPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: plannerSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: plannerBorder),
      ),
      child: child,
    );
  }
}
