import 'package:flutter/material.dart';
import 'eats_top_bar.dart';
import '../services/bc_eats_store.dart';

const eatsYellow = Color(0xFFFFC000);
const eatsRed = Color(0xFFEF1424);
const eatsGreen = Color(0xFF0AA735);
const eatsOrange = Color(0xFFEF9E00);

extension EatsPalette on BuildContext {
  bool get eatsDark => Theme.of(this).brightness == Brightness.dark;
  Color get eatsSurface => eatsDark ? const Color(0xFF1E2024) : Colors.white;
  Color get eatsBackground => eatsDark ? const Color(0xFF141518) : Colors.white;
  Color get eatsBorder =>
      eatsDark ? const Color(0xFF36383E) : const Color(0xFFE9E9ED);
  Color get eatsMuted =>
      eatsDark ? const Color(0xFFB8BBC2) : const Color(0xFF626268);
  Color get eatsInk =>
      eatsDark ? const Color(0xFFF7F7FA) : const Color(0xFF131416);
}

class EatsFlowScope extends InheritedWidget {
  final ValueChanged<int> navigate;
  const EatsFlowScope({
    super.key,
    required this.navigate,
    required super.child,
  });
  static EatsFlowScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EatsFlowScope>();
  @override
  bool updateShouldNotify(EatsFlowScope oldWidget) =>
      oldWidget.navigate != navigate;
}

class EatsPage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? action, leadingContent, titleWidget;

  const EatsPage({
    super.key,
    this.title = '',
    this.subtitle,
    required this.children,
    this.action,
    this.leadingContent,
    this.titleWidget,
  });

  @override
  Widget build(BuildContext context) {
    final contentTheme = Theme.of(context).copyWith(
      dividerColor: context.eatsBorder,
      textTheme: Theme.of(context).textTheme.apply(
        fontFamily: 'BCEatsPoppins',
        bodyColor: context.eatsInk,
        displayColor: context.eatsInk,
      ),
    );

    return Scaffold(
      backgroundColor: context.eatsBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Deliberately outside the BCEatsPoppins theme.
            // This keeps it identical to the main Eats top bar.
            const EatsTopBar(),

            Expanded(
              child: Theme(
                data: contentTheme,
                child: DefaultTextStyle(
                  style:
                      contentTheme.textTheme.bodyMedium ??
                      TextStyle(color: context.eatsInk),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        children: [
                          if (leadingContent != null) ...[
                            leadingContent!,
                            const SizedBox(height: 24),
                          ],

                          if (title.isNotEmpty || titleWidget != null) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child:
                                      titleWidget ??
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          height: 1.22,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                ),
                                if (action != null) ...[
                                  const SizedBox(width: 12),
                                  action!,
                                ],
                              ],
                            ),

                            if (subtitle != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                subtitle!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: context.eatsMuted,
                                  height: 1.5,
                                ),
                              ),
                            ],

                            const SizedBox(height: 20),
                          ],

                          ...children,

                          if (EatsFlowScope.maybeOf(context) == null)
                            SizedBox(
                              height: MediaQuery.paddingOf(context).bottom,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EatsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? tint, border;
  final bool shadow;
  const EatsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.tint,
    this.border,
    this.shadow = false,
  });
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: padding,
    decoration: BoxDecoration(
      color:
          tint?.withValues(alpha: context.eatsDark ? .12 : .045) ??
          context.eatsSurface,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(
        color:
            border ??
            (tint == null ? context.eatsBorder : tint!.withValues(alpha: .16)),
      ),
      boxShadow: shadow
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: .045),
                blurRadius: 7,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    ),
    child: child,
  );
}

class EatsAction extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined;
  final Color color;
  const EatsAction(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.outlined = false,
    this.color = eatsYellow,
  });
  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
      backgroundColor: WidgetStatePropertyAll(
        outlined ? Colors.transparent : color,
      ),
      foregroundColor: WidgetStatePropertyAll(
        outlined ? (color == eatsYellow ? eatsOrange : color) : Colors.black,
      ),
      side: outlined ? WidgetStatePropertyAll(BorderSide(color: color)) : null,
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 21), const SizedBox(width: 8)],
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    );
    return outlined
        ? OutlinedButton(style: style, onPressed: onPressed, child: child)
        : FilledButton(style: style, onPressed: onPressed, child: child);
  }
}

Widget eatsHeading(BuildContext context, String title) => Padding(
  padding: const EdgeInsets.only(top: 4, bottom: 12),
  child: Text(
    title,
    style: const TextStyle(
      fontSize: 18,
      height: 1.3,
      fontWeight: FontWeight.w600,
    ),
  ),
);

class EatsPair extends StatelessWidget {
  final Widget first, second;
  final double breakpoint, gap;
  final int firstFlex, secondFlex;
  const EatsPair({
    super.key,
    required this.first,
    required this.second,
    this.breakpoint = 360,
    this.gap = 14,
    this.firstFlex = 1,
    this.secondFlex = 1,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < breakpoint ||
          MediaQuery.textScalerOf(context).scale(14) > 22) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            first,
            SizedBox(height: gap),
            second,
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: firstFlex, child: first),
          SizedBox(width: gap),
          Expanded(flex: secondFlex, child: second),
        ],
      );
    },
  );
}

class EatsSummary extends StatelessWidget {
  final int subtotal, serviceFee, deliveryFee, count;
  final bool card, compact, showFulfilmentFee;
  final Color totalColor;
  final String totalLabel;
  const EatsSummary({
    super.key,
    required this.subtotal,
    required this.serviceFee,
    required this.deliveryFee,
    this.count = 0,
    this.card = true,
    this.compact = false,
    this.showFulfilmentFee = true,
    this.totalColor = eatsRed,
    this.totalLabel = 'Total',
  });
  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        _row(
          context,
          count > 0 ? 'Subtotal ($count items)' : 'Subtotal',
          subtotal,
        ),
        _row(context, 'Service Fee  ⓘ', serviceFee),
        if (showFulfilmentFee)
          _row(
            context,
            deliveryFee == 0 ? 'Pickup Fee' : 'Delivery Fee',
            deliveryFee,
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Divider(height: 1, color: context.eatsBorder),
        ),
        _row(
          context,
          totalLabel,
          subtotal + serviceFee + deliveryFee,
          bold: true,
        ),
      ],
    );
    return card ? EatsCard(child: content) : content;
  }

  Widget _row(
    BuildContext context,
    String label,
    int value, {
    bool bold = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: compact ? 10 : 14,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
              color: bold ? context.eatsInk : context.eatsMuted,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          money(value),
          style: TextStyle(
            fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            fontSize: bold ? (compact ? 17 : 23) : (compact ? 10 : 14),
            color: bold ? totalColor : context.eatsMuted,
          ),
        ),
      ],
    ),
  );
}

class EatsProgress extends StatelessWidget {
  final List<String> labels;
  final List<Widget>? icons;
  final List<String>? times;
  final int current;
  final Color color;
  final bool numbered, completed;
  const EatsProgress({
    super.key,
    required this.labels,
    required this.current,
    this.icons,
    this.times,
    this.color = eatsRed,
    this.numbered = false,
    this.completed = false,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final size = numbered ? 24.0 : 38.0;
      final width = c.maxWidth / labels.length;
      return Column(
        children: [
          SizedBox(
            height: size,
            child: Stack(
              children: [
                Positioned(
                  left: width / 2,
                  right: width / 2,
                  top: size / 2 - 1,
                  child: Row(
                    children: List.generate(
                      labels.length - 1,
                      (i) => Expanded(
                        child: Container(
                          height: 2,
                          color: i < current || completed
                              ? color
                              : context.eatsBorder,
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: List.generate(
                    labels.length,
                    (i) => Expanded(
                      child: Center(
                        child: Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                i < current ||
                                    completed ||
                                    (numbered && i == current)
                                ? color
                                : context.eatsSurface,
                            border: Border.all(
                              color: i <= current || completed
                                  ? color
                                  : context.eatsBorder,
                            ),
                          ),
                          child: Center(
                            child: i < current || completed
                                ? Icon(
                                    Icons.check,
                                    size: numbered ? 17 : 23,
                                    color: numbered || color == eatsGreen
                                        ? Colors.white
                                        : Colors.black,
                                  )
                                : numbered
                                ? Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      color: i == current
                                          ? Colors.white
                                          : context.eatsMuted,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : IconTheme(
                                    data: IconThemeData(
                                      color: i == current
                                          ? color
                                          : context.eatsMuted,
                                      size: 23,
                                    ),
                                    child: icons![i],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              labels.length,
              (i) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    children: [
                      Text(
                        labels[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: numbered ? 10 : 12,
                          height: 1.4,
                          color: !numbered && i == current
                              ? color
                              : context.eatsInk,
                          fontWeight: i == current
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                      if (times != null) ...[
                        const SizedBox(height: 7),
                        Text(
                          times![i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.eatsMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class EatsCircle extends StatelessWidget {
  final Widget child;
  final Color color;
  final double size;
  const EatsCircle({
    super.key,
    required this.child,
    this.color = eatsRed,
    this.size = 44,
  });
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withValues(alpha: .07),
    ),
    child: IconTheme(
      data: IconThemeData(color: color, size: size * .55),
      child: Center(child: child),
    ),
  );
}

class EatsInfo extends StatelessWidget {
  final Widget icon;
  final String title, subtitle;
  final Widget? action;
  final Color color;
  const EatsInfo({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
    this.color = eatsGreen,
  });
  @override
  Widget build(BuildContext context) => EatsCard(
    tint: color,
    child: LayoutBuilder(
      builder: (context, c) {
        final text = Row(
          children: [
            IconTheme(
              data: IconThemeData(color: color, size: 28),
              child: icon,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: color,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        );
        if (action == null) return text;
        return EatsPair(
          first: text,
          second: Align(alignment: Alignment.centerRight, child: action!),
          firstFlex: 3,
          secondFlex: 2,
          breakpoint: 520,
        );
      },
    ),
  );
}

class EatsProductImage extends StatelessWidget {
  final String path;
  final double width, height;
  const EatsProductImage({
    super.key,
    required this.path,
    required this.width,
    required this.height,
  });
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: Image.asset(
      path,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, error, stack) => Container(
        width: width,
        height: height,
        color: context.eatsBorder.withValues(alpha: .5),
        child: const Icon(Icons.restaurant, color: eatsOrange),
      ),
    ),
  );
}

Future<void> eatsSupport(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Contact Support'),
    content: const Text(
      'Please speak to the Campus Tuckshop team about your order. In-app support is not connected yet.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Close'),
      ),
    ],
  ),
);

class DroneIcon extends StatelessWidget {
  final double size;
  final Color? color;
  const DroneIcon({super.key, this.size = 28, this.color});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Drone',
    child: SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DronePainter(
          color ?? IconTheme.of(context).color ?? context.eatsInk,
        ),
      ),
    ),
  );
}

class _DronePainter extends CustomPainter {
  final Color color;
  const _DronePainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .065
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width / 2, size.height / 2);
    for (final x in [.2, .8]) {
      for (final y in [.25, .7]) {
        final rotor = Offset(size.width * x, size.height * y);
        canvas.drawLine(center, rotor, p);
        canvas.drawOval(
          Rect.fromCenter(
            center: rotor,
            width: size.width * .32,
            height: size.height * .13,
          ),
          p,
        );
      }
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: size.width * .28,
          height: size.height * .22,
        ),
        Radius.circular(size.width * .06),
      ),
      p,
    );
    canvas.drawLine(
      Offset(size.width * .4, size.height * .61),
      Offset(size.width * .35, size.height * .88),
      p,
    );
    canvas.drawLine(
      Offset(size.width * .6, size.height * .61),
      Offset(size.width * .65, size.height * .88),
      p,
    );
  }

  @override
  bool shouldRepaint(_DronePainter oldDelegate) => oldDelegate.color != color;
}
