import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../services/navigation_service.dart';

/// Turn instruction card displayed during active navigation.
class NavigationCard extends StatelessWidget {
  final NavInstruction instruction;
  final String destinationName;
  final int etaMinutes;
  final double remainingMeters;
  final TimeOfDay arrival;
  final VoidCallback onExit;

  const NavigationCard({
    super.key,
    required this.instruction,
    required this.destinationName,
    required this.etaMinutes,
    required this.remainingMeters,
    required this.arrival,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final isArrived =
        instruction.type ==
            TurnType.arrive;

    return Container(
      margin:
          const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius:
            BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _iconFor(
                  instruction.type,
                ),
                size: 34,
                color:
                    context.textPrimary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      instruction.label,
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            context.textPrimary,
                      ),
                    ),
                    if (!isArrived)
                      Text(
                        '${instruction.distanceMetersToTurn.round()} m',
                        style:
                            TextStyle(
                          fontSize: 22,
                          fontWeight:
                              FontWeight.w800,
                          color:
                              context.readableAccent(BcColors.primary),
                        ),
                      ),
                    Text(
                      'Towards $destinationName',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Divider(
            height: 24,
            color:
                context.subtleBorder,
          ),

          Wrap(
            spacing: 20,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(
                Icons.directions_walk,
                color: BcColors.teal,
                size: 20,
              ),


              _stat(
                context,
                'ETA',
                '$etaMinutes min',
              ),


              _stat(
                context,
                'Distance',
                '${remainingMeters.round()} m',
              ),


              _stat(
                context,
                'Arrival',
                arrival.format(context),
              ),


              ElevatedButton(
                onPressed: onExit,
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      BcColors.danger,
                  foregroundColor:
                      Colors.white,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                ),
                child:
                    const Text('Exit'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(
    BuildContext context,
    String label,
    String value,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color:
                context.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight:
                FontWeight.w700,
            color:
                context.textPrimary,
          ),
        ),
      ],
    );
  }

  IconData _iconFor(
    TurnType type,
  ) {
    switch (type) {
      case TurnType.left:
      case TurnType.sharpLeft:
        return Icons.turn_left;

      case TurnType.slightLeft:
        return Icons.turn_slight_left;

      case TurnType.right:
      case TurnType.sharpRight:
        return Icons.turn_right;

      case TurnType.slightRight:
        return Icons.turn_slight_right;

      case TurnType.straight:
        return Icons.straight;

      case TurnType.arrive:
        return Icons.flag_circle;
    }
  }
}