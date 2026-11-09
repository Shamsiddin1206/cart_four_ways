import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/cart.dart';
import 'summary_card.dart';

/// Summary card for any Cubit or Bloc whose state is [CartState].
/// The selector stops it rebuilding unless one of the totals changes.
class BlocSummaryCard<B extends StateStreamable<CartState>>
    extends StatelessWidget {
  const BlocSummaryCard({super.key});

  @override
  Widget build(BuildContext context) => BlocSelector<B, CartState, CartTotals>(
    selector: (state) => state.totals,
    builder: (context, totals) {
      debugPrint('[$B] SummaryCard rebuilt');
      return SummaryCard(totals: totals);
    },
  );
}
