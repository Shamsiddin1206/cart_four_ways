import 'package:flutter/material.dart';

import '../models/cart.dart';

/// Shows the SnackBar or MaterialBanner matching [state.status].
void showCheckoutResult(BuildContext context, CartState state) {
  final messenger = ScaffoldMessenger.of(context);
  switch (state.status) {
    case CheckoutStatus.idle:
    case CheckoutStatus.submitting:
      messenger.hideCurrentMaterialBanner();
    case CheckoutStatus.success:
      messenger.hideCurrentMaterialBanner();
      messenger.showSnackBar(
        SnackBar(content: Text('Order placed: ${state.orderId}')),
      );
    case CheckoutStatus.failure:
      messenger.hideCurrentMaterialBanner();
      messenger.showMaterialBanner(
        MaterialBanner(
          content: Text(state.checkoutError ?? 'Checkout failed'),
          actions: [
            TextButton(
              onPressed: () => messenger.hideCurrentMaterialBanner(),
              child: const Text('Dismiss'),
            ),
          ],
        ),
      );
  }
}
