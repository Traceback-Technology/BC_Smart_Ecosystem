import 'package:flutter/material.dart';
import '../constants/colors.dart';

class BcBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onTap;
  const BcBottomNavigationBar({super.key, this.selectedIndex = 1, this.onTap});

  static const _items = [
    (Icons.home_outlined, Icons.home, 'Home'),
    (Icons.map_outlined, Icons.map, 'Map'),
    (Icons.shopping_bag_outlined, Icons.shopping_bag, 'Orders'),
    (Icons.person_outline, Icons.person, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Align(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Material(
              color: context.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: context.subtleBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(children: [
                for (var index = 0; index < _items.length; index++)
                  Expanded(child: Semantics(
                    selected: index == selectedIndex,
                    button: true,
                    child: InkWell(
                      onTap: onTap == null ? null : () => onTap!(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(index == selectedIndex ? _items[index].$2 : _items[index].$1,
                            color: index == selectedIndex ? context.readableAccent(BcColors.primary) : context.textSecondary,
                            size: 26),
                          const SizedBox(height: 5),
                          Text(_items[index].$3, textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12,
                              fontWeight: index == selectedIndex ? FontWeight.w700 : FontWeight.w500,
                              color: index == selectedIndex ? context.readableAccent(BcColors.primary) : context.textSecondary)),
                        ]),
                      ),
                    ),
                  )),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
