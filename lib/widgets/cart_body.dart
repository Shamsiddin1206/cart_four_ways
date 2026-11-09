import 'package:flutter/material.dart';

import '../models/cart.dart';
import 'coupon_field.dart';

/// Dumb UI shared by all four styles: data in, callbacks out.
class CartBody extends StatelessWidget {
  const CartBody({
    super.key,
    required this.lines,
    required this.onAdd,
    required this.onQtyChanged,
    required this.appliedCoupon,
    required this.couponError,
    required this.onApplyCoupon,
    required this.summary,
    required this.isSubmitting,
    required this.onCheckout,
  });

  final List<CartLine> lines;
  final void Function(Product) onAdd;
  final void Function(String productId, int delta) onQtyChanged;
  final String? appliedCoupon;
  final String? couponError;
  final void Function(String code) onApplyCoupon;

  /// Passed in as a widget so each style can subscribe to totals its own way.
  final Widget summary;
  final bool isSubmitting;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: IgnorePointer(
          ignoring: isSubmitting,
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final p in catalog)
                      ActionChip(
                        label: Text(
                          '${p.name} · ${p.price.toStringAsFixed(0)}',
                        ),
                        onPressed: () => onAdd(p),
                      ),
                  ],
                ),
              ),
              CouponField(
                appliedCoupon: appliedCoupon,
                error: couponError,
                onApply: onApplyCoupon,
              ),
              if (lines.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('Cart is empty')),
                )
              else
                for (final l in lines)
                  ListTile(
                    key: ValueKey(l.product.id),
                    title: Text(l.product.name),
                    subtitle: Text(l.subtotal.toStringAsFixed(2)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          tooltip: 'Decrease',
                          onPressed: () => onQtyChanged(l.product.id, -1),
                        ),
                        Text('${l.qty}'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          tooltip: 'Increase',
                          onPressed: () => onQtyChanged(l.product.id, 1),
                        ),
                      ],
                    ),
                  ),
              summary,
            ],
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: isSubmitting || lines.isEmpty ? null : onCheckout,
            child: isSubmitting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Checkout'),
          ),
        ),
      ),
    ],
  );
}
