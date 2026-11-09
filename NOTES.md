# Lab notes: One Cart, Four Ways

## Part 1: Shared code

**Why is `CartLine` immutable with `copyWith` instead of a mutable `qty`?**
A new object per change means old and new state can be compared, undo snapshots stay correct, and nobody can change a line behind the state holder's back. Only `setState` would still "work" with mutation, because it rebuilds whatever the data looks like. That is the trap: the code seems fine until it moves to Riverpod, Cubit or Bloc, where the old and new state are the same object, `==` is true, and the UI silently stops updating. An undo stack would also hold references to objects that have since changed.

**Why does `CartBody` take callbacks?**
So it knows nothing about state management and the same widget serves all four styles. Importing a provider or bloc would tie it to one style. It is also testable by passing plain data.

## Part 2: setState

**T3: why storing `total` is a bug waiting to happen.** It would duplicate data derivable from `lines` and `coupon`. Every mutation would have to remember to update it, and the first one that forgets shows a wrong price. A getter cannot go stale.

**T4: what happens without `if (!mounted) return;`.** If the page is popped during the 1.5 s await, the `State` is disposed. Calling `setState` then throws "setState() called after dispose()", and `context` is no longer valid for showing a SnackBar.

**T6: observation.** Most of the widget test is locating chips, the text field and the button. Only one line checks the cart result.

**After T4, how would a second page read the cart?**
It can't, because the state is private to this `State` object. I would have to lift it above both pages and pass it down through constructors, or use an `InheritedWidget`, which is what the libraries in the next parts provide.

**After T5, where does `_history` live, and what happens on hot restart vs hot reload?**
It is a field of `_SetStateCartPageState`. Hot reload keeps `State` objects, so it survives. Hot restart recreates the app, so it is lost. Popping the page also loses it.

## Part 3: Riverpod

**T2: does `state = state.copyWith(coupon: code)` notify if the code is unchanged?**
Riverpod 3 filters updates with `==`. Without an override, `copyWith` returns a new object, identity equality says "different", and listeners are notified. With value-based `==` and `hashCode`, the new state equals the old one and listeners are not notified. The `ref.listen` plus `debugPrint` in the page shows this.

**T3: selective rebuild.** `RiverpodSummaryCard` is `const` in the page and selects only `totals`, a record of item count, subtotal, discount and total, which includes the `total` the lab asks for. The record is used because the card also displays the other three values. Typing in the coupon field never touches cart state, so the card's `debugPrint` stays silent. A quantity change prints it.

**T4: why no `mounted` check?** The notifier lives in the `ProviderContainer`, not the widget tree, and this provider is not `autoDispose`, so it is still alive after the await even if the page is gone. It only assigns `state` and touches no `BuildContext`. The `ref.listen` is removed with the widget, so no UI code runs after unmount.

**T5: what must `canUndoProvider` watch?** `_history` is a plain field and cannot be watched, so the provider does `ref.watch(cartProvider)` to recompute on each state change, then `ref.read(cartProvider.notifier).canUndo`. History is always updated before `state` is assigned, so the value is fresh.

**T5: `autoDispose` experiment.** With `NotifierProvider.autoDispose`, popping the page removes the last listener, so the provider and its notifier are disposed. Returning creates a new notifier: empty cart, empty history. The submitted code stays non-autoDispose so the cart survives navigation. With `autoDispose`, the checkout would also need a `ref.mounted` guard after the await.

**Where I used `ref.read` and `ref.watch`.**
`ref.read`:
1. `ref.read(cartProvider.notifier)` in the page: a handle for calling methods, no subscription needed.
2. `ref.read(checkoutApiProvider)` in `checkout()`: a one-off lookup inside a method.
3. `ref.read(cartProvider.notifier).canUndo` in `canUndoProvider`: watching the notifier object would never fire, since the object does not change.
4. `ref.read(cartProvider)` inside the status listener: a one-off value inside a callback.

`ref.watch`:
1. `ref.watch(cartProvider)` in the page: lines and coupon are displayed.
2. `ref.watch(canUndoProvider)` in the page: drives the Undo button.
3. `ref.watch(cartProvider.select(...))` in the summary card: display data, narrowed.
4. `ref.watch(cartProvider)` in `canUndoProvider`: the recompute trigger.

**Why does the summary card rebuild less often than the setState version?**
In the setState version every `setState` rebuilds the page and creates a new `SummaryCard`. The Riverpod card has its own subscription narrowed by `select`, so it only rebuilds when the selected values change.
