import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit(this._api) : super(const CartState());

  final CheckoutApi _api;

  void _commit(CartState next) {
    final committed = state.commit(next);
    if (committed == state) {
      debugPrint('[CartCubit] identical state, emit dropped');
    }
    emit(committed);
  }

  void add(Product p) => _commit(state.addProduct(p));
  void remove(String id) => _commit(state.removeProduct(id));
  void changeQty(String id, int delta) => _commit(state.changeQty(id, delta));
  void applyCoupon(String code) => _commit(state.applyCoupon(code));
  void undo() => emit(state.undone());

  Future<void> checkout() async {
    if (state.isSubmitting || state.lines.isEmpty) return;
    emit(state.startCheckout());
    try {
      final orderId = await _api.submit(state.total);
      if (isClosed) return; // emit after close() throws a StateError.
      emit(state.checkoutSucceeded(orderId));
    } on CheckoutException catch (e) {
      if (isClosed) return;
      emit(state.checkoutFailed(e.message));
    }
  }

  @override
  void onChange(Change<CartState> change) {
    super.onChange(change);
    debugPrint('[CartCubit] ${change.currentState} -> ${change.nextState}');
  }
}
