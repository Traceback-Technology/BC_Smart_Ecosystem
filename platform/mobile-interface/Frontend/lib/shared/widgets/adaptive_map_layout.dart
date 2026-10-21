import 'dart:math' as math;
import 'package:flutter/material.dart';

/// The map never shares a scrollable with the surrounding page.
/// Only controls scroll if text size or the available height requires it.
class AdaptiveMapLayout extends StatelessWidget {
  final List<Widget> header;
  final Widget map;
  final List<Widget> footer;
  const AdaptiveMapLayout({
    super.key, required this.header, required this.map, this.footer = const [],
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth >= 760) {
        return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
            width: math.min(400.0, constraints.maxWidth * .42),
            child: _controls(constraints.maxHeight, includeMap: false),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: map),
        ]);
      }
      return _controls(constraints.maxHeight, includeMap: true);
    },
  );

  Widget _controls(double height, {required bool includeMap}) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ConstrainedBox(
        constraints: BoxConstraints(maxHeight: height * (includeMap ? .38 : .52)),
        child: SingleChildScrollView(
          key: const ValueKey('map-header-scroll'),
          primary: false,
          child: Column(mainAxisSize: MainAxisSize.min, children: header),
        ),
      ),
      if (includeMap) Expanded(child: map) else const Spacer(),
      if (footer.isNotEmpty)
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: height * (includeMap ? .42 : .48)),
          child: SingleChildScrollView(
            key: const ValueKey('map-footer-scroll'),
            primary: false,
            // Anchor the bottom panel so expansion reveals the destinations.
            reverse: true,
            child: Column(mainAxisSize: MainAxisSize.min, children: footer),
          ),
        ),
    ],
  );
}
