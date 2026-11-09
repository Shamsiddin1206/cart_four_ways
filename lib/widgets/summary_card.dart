import 'package:flutter/material.dart';

import '../models/cart.dart';

/// Dumb summary: shows item count, subtotal, discount and total.
class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.totals});

  final CartTotals totals;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.all(12),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _row('Items', '${totals.itemCount}'),
          _row('Subtotal', totals.subtotal.toStringAsFixed(2)),
          _row('Discount', '-${totals.discount.toStringAsFixed(2)}'),
          _row(
            'Total',
            totals.total.toStringAsFixed(2),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
  );

  Widget _row(String label, String value, {TextStyle? style}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    ),
  );
}
