import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';

final checkoutApiProvider = Provider((ref) => CheckoutApi());

class CartNotifier extends Notifier<CartState> {
  final _history = <CartState>[];

  @override
  CartState build() => const CartState();

  bool get canUndo => _history.isNotEmpty && !state.isSubmitting;

  void _commit(CartState next) {
    if (next == state) return;
    _history.add(state.snapshot);
    state = next;
  }

  void add(Product p) => _commit(state.addProduct(p));
  void remove(String id) => _commit(state.removeProduct(id));
  void changeQty(String id, int delta) => _commit(state.changeQty(id, delta));
  void applyCoupon(String code) => _commit(state.applyCoupon(code));

  void undo() {
    if (canUndo) state = _history.removeLast();
  }

  Future<void> checkout() async {
    if (state.isSubmitting || state.lines.isEmpty) return;
    state = state.startCheckout();
    try {
      final orderId = await ref.read(checkoutApiProvider).submit(state.total);
      _history.clear(); // A placed order cannot be undone.
      state = state.checkoutSucceeded(orderId);
    } on CheckoutException catch (e) {
      state = state.checkoutFailed(e.message);
    }
  }
}

// Not autoDispose: the cart and its private history must outlive the page.
// With NotifierProvider.autoDispose both are lost when the page is popped.
final cartProvider = NotifierProvider<CartNotifier, CartState>(
  CartNotifier.new,
);

/// _history is not observable, so this watches the state (which changes on
/// every history change) and then reads the notifier's getter.
final canUndoProvider = Provider<bool>((ref) {
  ref.watch(cartProvider);
  return ref.read(cartProvider.notifier).canUndo;
});
