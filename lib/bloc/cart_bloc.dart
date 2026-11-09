import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';
import 'cart_event.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc(this._api) : super(const CartState()) {
    on<CartProductAdded>(
      (event, emit) => _apply(event, emit, state.addProduct(event.product)),
    );
    on<CartProductRemoved>(
      (event, emit) =>
          _apply(event, emit, state.removeProduct(event.productId)),
    );
    on<CartQtyChanged>(
      (event, emit) =>
          _apply(event, emit, state.changeQty(event.productId, event.delta)),
    );
    on<CartCouponApplied>(
      (event, emit) => _apply(event, emit, state.applyCoupon(event.code)),
    );
    on<CartCheckoutRequested>(_onCheckout, transformer: droppable());
    on<CartUndone>((event, emit) => emit(state.undone()));
  }

  final CheckoutApi _api;

  /// Edits of cart contents are undoable. Checkout is a real-world action,
  /// and undoing an undo would corrupt the stack, so neither is recorded.
  static bool _isUndoable(CartEvent event) => switch (event) {
    CartProductAdded() ||
    CartProductRemoved() ||
    CartQtyChanged() ||
    CartCouponApplied() => true,
    CartCheckoutRequested() || CartUndone() => false,
  };

  void _apply(CartEvent event, Emitter<CartState> emit, CartState next) =>
      emit(_isUndoable(event) ? state.commit(next) : next);

  Future<void> _onCheckout(
    CartCheckoutRequested event,
    Emitter<CartState> emit,
  ) async {
    if (state.lines.isEmpty) return;
    emit(state.startCheckout());
    try {
      final orderId = await _api.submit(state.total);
      if (emit.isDone) return;
      emit(state.checkoutSucceeded(orderId));
    } on CheckoutException catch (e) {
      if (emit.isDone) return;
      emit(state.checkoutFailed(e.message));
    }
  }
}
