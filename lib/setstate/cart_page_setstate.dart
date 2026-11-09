import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';
import '../widgets/cart_body.dart';
import '../widgets/checkout_feedback.dart';
import '../widgets/summary_card.dart';

class SetStateCartPage extends StatefulWidget {
  const SetStateCartPage({super.key});

  @override
  State<SetStateCartPage> createState() => _SetStateCartPageState();
}

class _SetStateCartPageState extends State<SetStateCartPage> {
  final _api = CheckoutApi();
  final _history = <CartState>[];
  CartState _state = const CartState();

  bool get _canUndo => _history.isNotEmpty && !_state.isSubmitting;

  void _commit(CartState next) {
    if (next == _state) return;
    setState(() {
      _history.add(_state.snapshot);
      _state = next;
    });
    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
  }

  void _add(Product p) => _commit(_state.addProduct(p));
  void _changeQty(String id, int delta) => _commit(_state.changeQty(id, delta));
  void _applyCoupon(String code) => _commit(_state.applyCoupon(code));

  void _undo() {
    setState(() => _state = _history.removeLast());
    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
  }

  Future<void> _checkout() async {
    if (_state.isSubmitting || _state.lines.isEmpty) return;
    setState(() => _state = _state.startCheckout());
    showCheckoutResult(context, _state);
    try {
      final orderId = await _api.submit(_state.total);
      if (!mounted) return; // The page may have been popped during the await.
      setState(() {
        _history.clear(); // A placed order cannot be undone.
        _state = _state.checkoutSucceeded(orderId);
      });
    } on CheckoutException catch (e) {
      if (!mounted) return;
      setState(() => _state = _state.checkoutFailed(e.message));
    }
    if (mounted) showCheckoutResult(context, _state);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Cart · setState'),
      actions: [
        IconButton(
          icon: const Icon(Icons.undo),
          tooltip: 'Undo',
          onPressed: _canUndo ? _undo : null,
        ),
      ],
    ),
    body: CartBody(
      lines: _state.lines,
      onAdd: _add,
      onQtyChanged: _changeQty,
      appliedCoupon: _state.coupon,
      couponError: _state.couponError,
      onApplyCoupon: _applyCoupon,
      summary: SummaryCard(totals: _state.totals),
      isSubmitting: _state.isSubmitting,
      onCheckout: _checkout,
    ),
  );
}
