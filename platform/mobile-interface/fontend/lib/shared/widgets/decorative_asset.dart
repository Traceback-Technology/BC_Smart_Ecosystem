import 'package:flutter/material.dart';

/// Optional transparent artwork. Missing images leave the interface usable.
class DecorativeAsset extends StatelessWidget {
  final String path;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  const DecorativeAsset(this.path, {super.key, this.fit = BoxFit.contain, this.alignment = Alignment.center});

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: Image.asset(path, fit: fit, alignment: alignment,
        errorBuilder: (_, __, ___) => const SizedBox.shrink()),
    ),
  );
}
