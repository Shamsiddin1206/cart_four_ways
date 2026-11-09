import '../models/cart.dart';

sealed class CartEvent {
  const CartEvent();
}

final class CartProductAdded extends CartEvent {
  const CartProductAdded(this.product);
  final Product product;
  @override
  String toString() => 'CartProductAdded(${product.name})';
}

final class CartProductRemoved extends CartEvent {
  const CartProductRemoved(this.productId);
  final String productId;
  @override
  String toString() => 'CartProductRemoved($productId)';
}

final class CartQtyChanged extends CartEvent {
  const CartQtyChanged(this.productId, this.delta);
  final String productId;
  final int delta;
  @override
  String toString() => 'CartQtyChanged($productId, $delta)';
}

final class CartCouponApplied extends CartEvent {
  const CartCouponApplied(this.code);
  final String code;
  @override
  String toString() => 'CartCouponApplied($code)';
}

final class CartCheckoutRequested extends CartEvent {
  const CartCheckoutRequested();
  @override
  String toString() => 'CartCheckoutRequested()';
}

final class CartUndone extends CartEvent {
  const CartUndone();
  @override
  String toString() => 'CartUndone()';
}
