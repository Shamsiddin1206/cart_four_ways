import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';
import '../widgets/bloc_summary_card.dart';
import '../widgets/cart_body.dart';
import '../widgets/checkout_feedback.dart';
import 'cart_bloc.dart';
import 'cart_event.dart';

class BlocCartPage extends StatelessWidget {
  const BlocCartPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => CartBloc(CheckoutApi()),
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Cart · Bloc'),
        actions: [
          BlocSelector<CartBloc, CartState, bool>(
            selector: (state) => state.canUndo,
            builder: (context, canUndo) => IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Undo',
              onPressed: canUndo
                  ? () => context.read<CartBloc>().add(const CartUndone())
                  : null,
            ),
          ),
        ],
      ),
      body: BlocListener<CartBloc, CartState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: showCheckoutResult,
        child: BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            final bloc = context.read<CartBloc>();
            return CartBody(
              lines: state.lines,
              onAdd: (p) => bloc.add(CartProductAdded(p)),
              onQtyChanged: (id, delta) => bloc.add(CartQtyChanged(id, delta)),
              appliedCoupon: state.coupon,
              couponError: state.couponError,
              onApplyCoupon: (code) => bloc.add(CartCouponApplied(code)),
              summary: const BlocSummaryCard<CartBloc>(),
              isSubmitting: state.isSubmitting,
              onCheckout: () => bloc.add(const CartCheckoutRequested()),
            );
          },
        ),
      ),
    ),
  );
}
