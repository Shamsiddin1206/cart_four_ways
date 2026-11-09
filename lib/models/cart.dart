import 'package:flutter/foundation.dart' show listEquals;

class Product {
  const Product({required this.id, required this.name, required this.price});
  final String id;
  final String name;
  final double price;
}

const catalog = [
  Product(id: 'p1', name: 'Keyboard', price: 49),
  Product(id: 'p2', name: 'Mouse', price: 25),
  Product(id: 'p3', name: 'Monitor', price: 199),
];

class CartLine {
  const CartLine({required this.product, required this.qty});
  final Product product;
  final int qty;

  double get subtotal => product.price * qty;

  CartLine copyWith({int? qty}) =>
      CartLine(product: product, qty: qty ?? this.qty);

  @override
  bool operator ==(Object other) =>
      other is CartLine && other.product.id == product.id && other.qty == qty;

  @override
  int get hashCode => Object.hash(product.id, qty);
}

/// Pure, style-independent cart logic. Every state holder calls these.
extension CartLines on List<CartLine> {
  List<CartLine> withProduct(Product p) {
    final i = indexWhere((l) => l.product.id == p.id);
    if (i == -1) return [...this, CartLine(product: p, qty: 1)];
    return [
      for (final l in this)
        l.product.id == p.id ? l.copyWith(qty: l.qty + 1) : l,
    ];
  }

  List<CartLine> without(String productId) => [
    for (final l in this)
      if (l.product.id != productId) l,
  ];

  /// Applies [delta] to one line; a quantity that reaches zero removes it.
  List<CartLine> changeQty(String productId, int delta) => [
    for (final l in this)
      if (l.product.id != productId)
        l
      else if (l.qty + delta > 0)
        l.copyWith(qty: l.qty + delta),
  ];

  double get subtotal => fold(0, (s, l) => s + l.subtotal);
  int get itemCount => fold(0, (s, l) => s + l.qty);
}

enum CheckoutStatus { idle, submitting, success, failure }

const validCoupon = 'SAVE10';
const _discountRate = 0.10;

/// Sentinel that lets [CartState.copyWith] tell "not passed" from "set to null".
const _unset = Object();

/// The values shown on the summary card. Records compare by value, so a
/// selector returning this only triggers a rebuild when a number changes.
typedef CartTotals = ({
  int itemCount,
  double subtotal,
  double discount,
  double total,
});

/// Immutable state shared by all four styles.
///
/// [history] is only populated by the Cubit and the Bloc. setState and
/// Riverpod keep their undo stack in a private field, as the lab asks.
class CartState {
  const CartState({
    this.lines = const [],
    this.coupon,
    this.couponError,
    this.status = CheckoutStatus.idle,
    this.orderId,
    this.checkoutError,
    this.history = const [],
  });

  final List<CartLine> lines;
  final String? coupon;
  final String? couponError;
  final CheckoutStatus status;
  final String? orderId;
  final String? checkoutError;
  final List<CartState> history;

  // Derived values: always computed, never stored.
  int get itemCount => lines.itemCount;
  double get subtotal => lines.subtotal;
  double get discount => coupon == validCoupon ? subtotal * _discountRate : 0.0;
  double get total => subtotal - discount;
  CartTotals get totals => (
    itemCount: itemCount,
    subtotal: subtotal,
    discount: discount,
    total: total,
  );
  bool get isSubmitting => status == CheckoutStatus.submitting;
  bool get canUndo => history.isNotEmpty && !isSubmitting;

  CartState copyWith({
    List<CartLine>? lines,
    Object? coupon = _unset,
    Object? couponError = _unset,
    CheckoutStatus? status,
    Object? orderId = _unset,
    Object? checkoutError = _unset,
    List<CartState>? history,
  }) => CartState(
    lines: lines ?? this.lines,
    coupon: identical(coupon, _unset) ? this.coupon : coupon as String?,
    couponError: identical(couponError, _unset)
        ? this.couponError
        : couponError as String?,
    status: status ?? this.status,
    orderId: identical(orderId, _unset) ? this.orderId : orderId as String?,
    checkoutError: identical(checkoutError, _unset)
        ? this.checkoutError
        : checkoutError as String?,
    history: history ?? this.history,
  );

  // Pure transitions, so no state holder repeats cart rules.
  CartState _withoutCheckoutResult() =>
      copyWith(status: CheckoutStatus.idle, orderId: null, checkoutError: null);

  CartState addProduct(Product p) =>
      _withoutCheckoutResult().copyWith(lines: lines.withProduct(p));

  CartState removeProduct(String productId) =>
      _withoutCheckoutResult().copyWith(lines: lines.without(productId));

  CartState changeQty(String productId, int delta) => _withoutCheckoutResult()
      .copyWith(lines: lines.changeQty(productId, delta));

  CartState applyCoupon(String code) => code == validCoupon
      ? _withoutCheckoutResult().copyWith(coupon: code, couponError: null)
      : _withoutCheckoutResult().copyWith(
          coupon: null,
          couponError: 'Invalid coupon code',
        );

  CartState startCheckout() => copyWith(
    status: CheckoutStatus.submitting,
    orderId: null,
    checkoutError: null,
  );

  CartState checkoutSucceeded(String orderId) =>
      CartState(status: CheckoutStatus.success, orderId: orderId);

  CartState checkoutFailed(String message) =>
      copyWith(status: CheckoutStatus.failure, checkoutError: message);

  /// This state as an undo entry: no nested history, no stale checkout result.
  CartState get snapshot =>
      _withoutCheckoutResult().copyWith(history: const []);

  /// Moves to [next] and records this state in [history]. A no-op edit is
  /// returned unchanged so it can neither notify nor add an undo entry.
  CartState commit(CartState next) =>
      next == this ? this : next.copyWith(history: [...history, snapshot]);

  CartState undone() => canUndo
      ? history.last.copyWith(history: history.sublist(0, history.length - 1))
      : this;

  @override
  bool operator ==(Object other) =>
      other is CartState &&
      listEquals(other.lines, lines) &&
      other.coupon == coupon &&
      other.couponError == couponError &&
      other.status == status &&
      other.orderId == orderId &&
      other.checkoutError == checkoutError &&
      listEquals(other.history, history);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(lines),
    coupon,
    couponError,
    status,
    orderId,
    checkoutError,
    Object.hashAll(history),
  );

  @override
  String toString() =>
      'CartState(items: $itemCount, total: ${total.toStringAsFixed(2)}, '
      'coupon: $coupon, status: ${status.name}, undo: ${history.length})';
}
