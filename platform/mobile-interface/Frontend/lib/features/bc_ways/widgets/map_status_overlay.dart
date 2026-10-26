import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Floating controls with a pinned status message below the scrollable cards.
class MapStatusOverlay extends StatefulWidget {
  final double viewportHeight;
  final List<Widget> children;
  final List<Widget> pinnedChildren;

  const MapStatusOverlay({
    super.key,
    required this.viewportHeight,
    required this.children,
    this.pinnedChildren = const [],
  });

  @override
  State<MapStatusOverlay> createState() => _MapStatusOverlayState();
}

class _MapStatusOverlayState extends State<MapStatusOverlay> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty && widget.pinnedChildren.isEmpty) {
      return const SizedBox.shrink();
    }

    // Use the available map height while leaving the GPS button clear.
    final maxHeight = math.max(0.0, widget.viewportHeight - 88.0);

    return Positioned(
      top: 12,
      left: 12,
      right: 12,
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 440, maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.children.isNotEmpty)
                Flexible(
                  fit: FlexFit.loose,
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      primary: false,
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < widget.children.length; i++) ...[
                            if (i > 0) const SizedBox(height: 8),
                            widget.children[i],
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              if (widget.pinnedChildren.isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    4,
                    widget.children.isEmpty ? 4 : 8,
                    4,
                    4,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (
                        var i = 0;
                        i < widget.pinnedChildren.length;
                        i++
                      ) ...[
                        if (i > 0) const SizedBox(height: 8),
                        widget.pinnedChildren[i],
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
