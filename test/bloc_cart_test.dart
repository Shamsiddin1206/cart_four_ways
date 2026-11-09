import 'package:bloc_test/bloc_test.dart';
import 'package:cart_four_ways/bloc/cart_bloc.dart';
import 'package:cart_four_ways/bloc/cart_event.dart';
import 'package:cart_four_ways/models/cart.dart';
import 'package:cart_four_ways/services/checkout_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCheckoutApi extends Mock implements CheckoutApi {}

void main() {
  setUpAll(() => registerFallbackValue(0.0));

  final keyboard = catalog.first;
  late MockCheckoutApi api;

  const empty = CartState();
  final oneKeyboard = empty.commit(empty.addProduct(keyboard));
  final twoKeyboards = oneKeyboard.commit(oneKeyboard.addProduct(keyboard));
  final couponApplied = twoKeyboards.commit(twoKeyboards.applyCoupon('SAVE10'));

  setUp(() => api = MockCheckoutApi());

  blocTest<CartBloc, CartState>(
    'emits exactly three states for two adds and a coupon',
    build: () => CartBloc(api),
    act: (b) => b
      ..add(CartProductAdded(keyboard))
      ..add(CartProductAdded(keyboard))
      ..add(const CartCouponApplied('SAVE10')),
    expect: () => [oneKeyboard, twoKeyboards, couponApplied],
    verify: (b) => expect(b.state.total, closeTo(88.2, 1e-9)),
  );

  blocTest<CartBloc, CartState>(
    'failed checkout emits submitting then failure and keeps the lines',
    setUp: () =>
        when(() => api.submit(any()))
            .thenThrow(const CheckoutException('Card declined')),
    build: () => CartBloc(api),
    seed: () => oneKeyboard,
    act: (b) => b.add(const CartCheckoutRequested()),
    wait: const Duration(milliseconds: 20),
    expect: () => [
      isA<CartState>().having(
        (s) => s.status,
        'status',
        CheckoutStatus.submitting,
      ),
      isA<CartState>()
          .having((s) => s.status, 'status', CheckoutStatus.failure)
          .having((s) => s.lines, 'lines', isNotEmpty),
    ],
  );

  blocTest<CartBloc, CartState>(
    'droppable lets only one of two checkout requests through',
    setUp: () => when(() => api.submit(any())).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return 'ORD-1';
    }),
    build: () => CartBloc(api),
    seed: () => oneKeyboard,
    act: (b) => b
      ..add(const CartCheckoutRequested())
      ..add(const CartCheckoutRequested()),
    wait: const Duration(milliseconds: 50),
    expect: () => [
      isA<CartState>().having(
        (s) => s.status,
        'status',
        CheckoutStatus.submitting,
      ),
      isA<CartState>().having(
        (s) => s.status,
        'status',
        CheckoutStatus.success,
      ),
    ],
    verify: (_) => verify(() => api.submit(any())).called(1),
  );
}
