import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/bc_eats_colors.dart';
import '../models/bc_eats_product.dart';
import '../services/bc_eats_store.dart';

const _nameStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
const _descriptionStyle = TextStyle(fontSize: 12);
const _priceStyle = TextStyle(
  fontSize: 17,
  fontWeight: FontWeight.bold,
  color: BcEatsColors.red,
);
const _quantityStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.bold);
const _unavailableStyle = TextStyle(fontSize: 10, fontWeight: FontWeight.w600);

Size _measure(
  BuildContext context,
  String text,
  TextStyle style,
  double width, {
  int? lines,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: DefaultTextStyle.of(context).style.merge(style),
    ),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    locale: Localizations.maybeLocaleOf(context),
    maxLines: lines,
    ellipsis: lines == null ? null : '…',
  )..layout(maxWidth: width);
  final size = painter.size;
  painter.dispose();
  return size;
}

/// Card extent follows the actual font, text scale and footer layout.
class EatsProductCard extends StatelessWidget {
  final BcEatsProduct product;
  const EatsProductCard({super.key, required this.product});

  static double heightFor(
    BuildContext context,
    BcEatsProduct product,
    double width,
  ) {
    final contentWidth = width - 24;
    final title = _measure(
      context,
      product.name,
      _nameStyle,
      contentWidth,
      lines: 2,
    ).height;
    final description = product.description.isEmpty
        ? 0.0
        : _measure(
            context,
            product.description,
            _descriptionStyle,
            contentWidth,
            lines: 2,
          ).height;
    return 125 +
        18 +
        title +
        description +
        20 +
        EatsProductFooter.heightFor(context, product, contentWidth) +
        2;
  }

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: product.isAvailable ? 1 : .55,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 125,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                product.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (_, error, stack) => const Icon(
                  Icons.fastfood,
                  color: BcEatsColors.red,
                  size: 48,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _nameStyle,
            ),
          ),
          if (product.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                product.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _descriptionStyle.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: EatsProductFooter(product: product),
          ),
        ],
      ),
    ),
  );
}

class EatsProductFooter extends StatelessWidget {
  final BcEatsProduct product;
  const EatsProductFooter({super.key, required this.product});

  static Size _controlsSize(BuildContext context, BcEatsProduct product) {
    final count = BcEatsStore.instance.quantityFor(product.id);
    final size = _measure(context, '$count', _quantityStyle, double.infinity);
    // Reserve the same space before the first addition to avoid card jumps.
    return Size(
      68 + math.max(24.0, size.width + 8),
      math.max(34.0, size.height),
    );
  }

  static double heightFor(
    BuildContext context,
    BcEatsProduct product,
    double width,
  ) {
    final price = _measure(context, product.formattedPrice, _priceStyle, width);
    final controls = _controlsSize(context, product);
    final inline = price.width + 8 + controls.width <= width;
    final unavailable = product.isAvailable
        ? 0.0
        : 4 + _measure(context, 'Unavailable', _unavailableStyle, width).height;
    return (inline
            ? math.max(price.height, controls.height)
            : price.height + 6 + controls.height) +
        unavailable;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: BcEatsStore.instance,
    builder: (context, _) => LayoutBuilder(
      builder: (context, constraints) {
        final store = BcEatsStore.instance;
        final count = store.quantityFor(product.id);
        final size = _controlsSize(context, product);
        final price = Text(product.formattedPrice, style: _priceStyle);
        Widget button(bool add) => SizedBox(
          width: 34,
          height: 34,
          child: IconButton.filled(
            key: ValueKey('eats-${add ? 'add' : 'remove'}-${product.id}'),
            tooltip: '${add ? 'Add' : 'Remove'} ${product.name}',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
            style: IconButton.styleFrom(
              backgroundColor: add ? BcEatsColors.red : const Color(0xFF8A8A8A),
              foregroundColor: Colors.white,
            ),
            onPressed: add
                ? (product.isAvailable ? () => store.add(product) : null)
                : () => store.decrease(product.id),
            icon: Icon(add ? Icons.add : Icons.remove, size: 18),
          ),
        );
        final controls = Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (count > 0) ...[
              button(false),
              SizedBox(
                width: size.width - 68,
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  key: ValueKey('eats-quantity-${product.id}'),
                  style: _quantityStyle,
                ),
              ),
            ],
            button(true),
          ],
        );
        final inline =
            _measure(
                  context,
                  product.formattedPrice,
                  _priceStyle,
                  constraints.maxWidth,
                ).width +
                8 +
                size.width <=
            constraints.maxWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (inline)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [price, controls],
              )
            else ...[
              price,
              const SizedBox(height: 6),
              controls,
            ],
            if (!product.isAvailable) ...[
              const SizedBox(height: 4),
              Text(
                'Unavailable',
                style: _unavailableStyle.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        );
      },
    ),
  );
}
