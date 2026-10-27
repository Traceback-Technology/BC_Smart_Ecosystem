import 'package:flutter/material.dart';
import '../../../shared/widgets/campus_logo.dart';
import '../../bc_ways/constants/colors.dart';
import '../constants/bc_eats_colors.dart';

/// Exact copy of the existing Eats top bar, reused by the order flow.
class EatsTopBar extends StatelessWidget {
  const EatsTopBar({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 18, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: () async {
              final popped = await Navigator.of(context).maybePop();
              if (!popped && context.mounted) {
                Navigator.of(context, rootNavigator: true).maybePop();
              }
            },
            icon: const Icon(Icons.arrow_back, size: 28),
          ),

          const CampusLogo(width: 30, height: 30),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'BC',
                      style: TextStyle(
                        fontSize: 20,
                        height: 1.0,
                        fontWeight: FontWeight.w900,
                        color: BcEatsColors.red,
                      ),
                    ),

                    const SizedBox(width: 5),

                    Text(
                      'EATS',
                      style: TextStyle(
                        fontSize: 20,
                        height: 1.0,
                        fontWeight: FontWeight.w900,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 1),

                Text(
                  'Campus Tuckshop',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.0,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none, size: 29),

              Positioned(
                right: -4,
                top: -5,
                child: Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE31B23),
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}
