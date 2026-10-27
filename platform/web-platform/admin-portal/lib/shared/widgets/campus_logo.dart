import 'package:flutter/material.dart';

/// Uses the supplied artwork for the current theme, without a backing panel.
class CampusLogo extends StatelessWidget {
  final double height;
  final double? width;
  const CampusLogo({super.key, this.height = 48, this.width});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: height, width: width,
      child: Image.asset(
        theme.brightness == Brightness.dark
          ? 'assets/images/BC_Logo_2.png' : 'assets/images/BC_Logo.png',
        fit: BoxFit.contain,
        semanticLabel: 'Belgium Campus iTversity',
        errorBuilder: (_, __, ___) => Center(child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('BC', style: TextStyle(color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w900, fontSize: 22)),
        )),
      ),
    );
  }
}
