import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/cart_body.dart';
import '../widgets/checkout_feedback.dart';
import '../widgets/summary_card.dart';
import 'cart_notifier.dart';

class RiverpodCartPage extends ConsumerWidget {
  const RiverpodCartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(cartProvider, (previous, next) {
      debugPrint('[Riverpod] notified: $next');
    });
    ref.listen(cartProvider.select((s) => s.status), (previous, next) {
      showCheckoutResult(context, ref.read(cartProvider));
    });

    final state = ref.watch(cartProvider);
    final canUndo = ref.watch(canUndoProvider);
    final cart = ref.read(cartProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart · Riverpod'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
            onPressed: canUndo ? cart.undo : null,
          ),
        ],
      ),
      body: CartBody(
        lines: state.lines,
        onAdd: cart.add,
        onQtyChanged: cart.changeQty,
        appliedCoupon: state.coupon,
        couponError: state.couponError,
        onApplyCoupon: cart.applyCoupon,
        summary: const RiverpodSummaryCard(),
        isSubmitting: state.isSubmitting,
        onCheckout: cart.checkout,
      ),
    );
  }
}

/// const in the page, so only its own select can make it rebuild.
class RiverpodSummaryCard extends ConsumerWidget {
  const RiverpodSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(cartProvider.select((s) => s.totals));
    debugPrint('[Riverpod] SummaryCard rebuilt');
    return SummaryCard(totals: totals);
  }
}
