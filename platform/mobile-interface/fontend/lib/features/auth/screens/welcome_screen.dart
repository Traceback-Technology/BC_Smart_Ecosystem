import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../shared/widgets/campus_logo.dart';
import '../../../shared/widgets/decorative_asset.dart';
import '../../bc_ways/constants/colors.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onStudentTap;
  final VoidCallback onVisitorTap;
  const WelcomeScreen({super.key, required this.onStudentTap, required this.onVisitorTap});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(fit: StackFit.expand, children: [
      const Positioned.fill(child: Align(
        alignment: Alignment.topCenter,
        child: FractionallySizedBox(
          widthFactor: 1,
          heightFactor: .5,
          child: DecorativeAsset(
            'assets/images/welcome_map.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
      )),
      SafeArea(child: Column(children: [
        Expanded(child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: LayoutBuilder(builder: (context, constraints) {
        final landscape = constraints.maxWidth >= 650 && constraints.maxWidth > constraints.maxHeight;
        final width = math.min(constraints.maxWidth, landscape ? 900.0 : 480.0);
        // The content has a compact natural height. Only unusually small windows
        // or very large accessibility text need the final scale-down fit.
        return Center(child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(width: width,
            child: landscape
              ? Row(children: [
                  Expanded(child: _hero(context)),
                  const SizedBox(width: 24),
                  Expanded(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    _actions(context),
                    const SizedBox(height: 28),
                    _closing(context, compact: true),
                  ])),
                ])
              : Column(mainAxisSize: MainAxisSize.min, children: [
                  _hero(context),
                  const SizedBox(height: 20),
                  _actions(context),
                  const SizedBox(height: 32),
                  _closing(context),
                  const SizedBox(height: 24),
                ]),
          ),
        ));
      }),
        )),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8, runSpacing: 8,
            children: [
              Icon(Icons.brightness_auto_outlined, color: context.textSecondary, size: 20),
              Text('Device theme · ${context.isDark ? 'Dark' : 'Light'}',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textSecondary, fontSize: 13)),
            ],
          ),
        ),
      ])),
    ]),
  );

  // Part of the main content, with deliberate gaps around the artwork.
  Widget _closing(BuildContext context, {bool compact = false}) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(children: [
        const Expanded(child: Divider()),
        const SizedBox(width: 8),
        Expanded(flex: 4, child: Text('Smart campus, Smart you.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.textPrimary, fontSize: 12))),
        const SizedBox(width: 8),
        const Expanded(child: Divider()),
      ]),
      const SizedBox(height: 20),
      SizedBox(height: compact ? 36 : 50,
        child: const DecorativeAsset('assets/images/welcome_skyline.png')),
    ],
  );

  Widget _hero(BuildContext context) => Stack(children: [
    Column(mainAxisSize: MainAxisSize.min, children: [
      // Branding belongs to the welcome artwork, rather than a separate header.
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const CampusLogo(width: 44, height: 44),
        const SizedBox(width: 8),
        Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('BELGIUM CAMPUS', style: TextStyle(color: context.textPrimary,
            fontSize: 14, fontWeight: FontWeight.w800)),
          Text('iTversity', style: TextStyle(color: context.textSecondary, fontSize: 13)),
        ])),
      ]),
      _pins(context, top: true),
      Text('Welcome to', textAlign: TextAlign.center, style: TextStyle(
        color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 3),
      Text.rich(TextSpan(children: [
        TextSpan(text: 'BC ', style: TextStyle(color: context.readableAccent(BcColors.primary))),
        const TextSpan(text: 'WAYS '),
        TextSpan(text: '& ', style: TextStyle(color: context.bcColors.error)),
        TextSpan(text: 'EATS', style: TextStyle(color: context.readableAccent(BcColors.primary))),
      ]), textAlign: TextAlign.center,
        style: TextStyle(color: context.textPrimary, fontSize: 24, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 20, height: 2, color: Colors.amber),
        Container(width: 20, height: 2, color: Colors.red),
        Container(width: 20, height: 2, color: Colors.cyan),
      ]),
      const SizedBox(height: 8),
      Text('Navigate Belgium Campus smarter.\nOrder easier. Live better.', textAlign: TextAlign.center,
        style: TextStyle(color: context.textSecondary, fontSize: 12, height: 1.3)),
      _pins(context, top: false),
    ]),
  ]);

  Widget _pins(BuildContext context, {required bool top}) => LayoutBuilder(builder: (context, constraints) {
    final scale = MediaQuery.textScalerOf(context).scale(10) / 10;
    final width = constraints.maxWidth;
    return SizedBox(height: 44 * scale, child: Stack(children: [
      Positioned(top: 3 * scale, left: 0, width: width * .32,
        child: _pin(context, top ? 'LIBRARY' : 'MAIN GATE', top ? Colors.cyan : Colors.amber)),
      Positioned(top: 18 * scale, left: width * .32, width: width * .36,
        child: _pin(context, top ? 'RECEPTION' : 'CLASSROOM IOTA', Colors.redAccent)),
      Positioned(top: 7 * scale, right: 0, width: width * .32,
        child: _pin(context, top ? 'CAFETERIA' : 'SMART CITIES', top ? Colors.red : Colors.cyan)),
    ]));
  });

  Widget _pin(BuildContext context, String label, Color color) => Text.rich(TextSpan(children: [
    WidgetSpan(alignment: PlaceholderAlignment.middle,
      child: Icon(Icons.location_on, size: 12, color: context.readableAccent(color))),
    TextSpan(text: ' $label'),
  ]), style: TextStyle(color: context.textSecondary, fontSize: 8, fontWeight: FontWeight.w700));

  Widget _actions(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _option(icon: Icons.school, title: 'Continue as Student',
        subtitle: 'Access your dashboard, save places, view orders and more.',
        background: const Color(0xFFFFC107), foreground: Colors.black, onTap: onStudentTap),
      const SizedBox(height: 10),
      _option(icon: Icons.people, title: 'Continue as Guest / Parent',
        subtitle: 'Explore campus, get directions and order food.',
        background: const Color(0xFF8B0000), foreground: Colors.white, onTap: onVisitorTap),
    ],
  );

  Widget _option({required IconData icon, required String title, required String subtitle,
    required Color background, required Color foreground, required VoidCallback onTap}) => Material(
    color: background, borderRadius: BorderRadius.circular(16), clipBehavior: Clip.antiAlias,
    child: InkWell(onTap: onTap, child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(children: [
        Icon(icon, size: 28, color: foreground), const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: foreground, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(subtitle, style: TextStyle(color: foreground, fontSize: 11, height: 1.3)),
        ])),
        const SizedBox(width: 4), Icon(Icons.chevron_right, size: 18, color: foreground),
      ]),
    )),
  );
}
