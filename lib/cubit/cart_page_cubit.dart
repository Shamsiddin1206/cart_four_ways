import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';
import '../widgets/bloc_summary_card.dart';
import '../widgets/cart_body.dart';
import '../widgets/checkout_feedback.dart';
import 'cart_cubit.dart';

class CubitCartPage extends StatelessWidget {
  const CubitCartPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => CartCubit(CheckoutApi()),
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Cart · Cubit'),
        actions: [
          BlocSelector<CartCubit, CartState, bool>(
            selector: (state) => state.canUndo,
            builder: (context, canUndo) => IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Undo',
              onPressed: canUndo ? context.read<CartCubit>().undo : null,
            ),
          ),
        ],
      ),
      body: BlocListener<CartCubit, CartState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: showCheckoutResult,
        child: BlocBuilder<CartCubit, CartState>(
          builder: (context, state) {
            final cubit = context.read<CartCubit>();
            return CartBody(
              lines: state.lines,
              onAdd: cubit.add,
              onQtyChanged: cubit.changeQty,
              appliedCoupon: state.coupon,
              couponError: state.couponError,
              onApplyCoupon: cubit.applyCoupon,
              summary: const BlocSummaryCard<CartCubit>(),
              isSubmitting: state.isSubmitting,
              onCheckout: cubit.checkout,
            );
          },
        ),
      ),
    ),
  );
}
