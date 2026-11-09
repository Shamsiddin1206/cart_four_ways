import 'package:bloc_test/bloc_test.dart';
import 'package:cart_four_ways/cubit/cart_cubit.dart';
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

  blocTest<CartCubit, CartState>(
    'emits exactly three states for two adds and a coupon',
    build: () => CartCubit(api),
    act: (c) {
      c.add(keyboard);
      c.add(keyboard);
      c.applyCoupon('SAVE10');
    },
    expect: () => [oneKeyboard, twoKeyboards, couponApplied],
    verify: (c) => expect(c.state.total, closeTo(88.2, 1e-9)),
  );

  blocTest<CartCubit, CartState>(
    'failed checkout emits submitting then failure and keeps the lines',
    setUp: () =>
        when(() => api.submit(any()))
            .thenThrow(const CheckoutException('Card declined')),
    build: () => CartCubit(api),
    seed: () => oneKeyboard,
    act: (c) => c.checkout(),
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

  blocTest<CartCubit, CartState>(
    'applying the same coupon twice drops the second emit',
    build: () => CartCubit(api),
    seed: () => oneKeyboard,
    act: (c) {
      c.applyCoupon('SAVE10');
      c.applyCoupon('SAVE10');
    },
    expect: () => hasLength(1),
  );
}
