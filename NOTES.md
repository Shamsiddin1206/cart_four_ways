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

## Part 4: Cubit

**T2: dropped emit.** `BlocBase.emit` ignores a state equal to the current one. On a second identical coupon `_commit` prints "identical state, emit dropped" and `onChange` does not fire. A `blocTest` also asserts this.

**T4: `emit` after `close()`.** It throws a `StateError`, which is why `checkout()` checks `isClosed` after the await.

**T5: why a getter fails.** `BlocBuilder` only rebuilds on emitted states, and a getter on the cubit emits nothing. So history is part of `CartState` and `canUndo` is a getter on the state, which every emit carries.

**T6: comparison with Riverpod.** The Riverpod test asserts only the end state. `blocTest` asserts the whole sequence, so a missing or extra intermediate state fails the test.

**What would break if `BlocProvider` were inside `CartBody`?**
The AppBar's Undo button and the `BlocListener` are above `CartBody` and could not find the cubit, giving a `ProviderNotFoundException`. `CartBody` would also stop being style-independent and could not be shared.

**Riverpod equivalents.**

| flutter_bloc | Riverpod |
|---|---|
| `BlocProvider` | `NotifierProvider` plus the root `ProviderScope` |
| `BlocBuilder` | `ref.watch` (or `Consumer`) |
| `BlocListener` | `ref.listen` |
| `context.read` | `ref.read` |
| `buildWhen` | `select` |

## Part 5: Bloc

**T2: what extra information does the transition log give?** `onTransition` shows current state, the event and next state. The Cubit's `onChange` shows only current and next, so you can see what changed but not why.

**T4: droppable.** With `droppable()`, taps made while the first checkout runs are discarded, so the API is called once. A plain Cubit would start a new `checkout()` per call, so it needs the manual `if (state.isSubmitting) return;` guard. Note that bloc's default transformer is concurrent, not sequential: without `droppable()`, three taps would start three API calls.

**T5: which events are undoable?** `CartProductAdded`, `CartProductRemoved`, `CartQtyChanged` and `CartCouponApplied` change what the user is editing, so they are undoable. `CartCheckoutRequested` is a real-world action that cannot be taken back, and recording `CartUndone` would make undo undo itself. The exhaustive `switch` in `_isUndoable` means a new event will not compile until it is classified.

**When is the event layer worth its boilerplate?**
Clearly better than Cubit: checkout, where one `transformer: droppable()` replaces a hand-written guard and every attempt is a named event in the log. Pure overhead: the quantity stepper, where the event class only forwards two arguments to a pure helper.

**Which styles implement "drop duplicate taps" declaratively?**
Only Bloc, through the transformer. In setState, Riverpod and Cubit it is imperative: `if (state.isSubmitting) return;` at the top of `checkout`, plus disabling the button.

## Checkpoint questions

**1. Where state lives and when it dies.**
- setState: in the `State` object; dies when the page leaves the tree.
- Riverpod: in the `ProviderContainer` under the root `ProviderScope`; dies with the app, or when the last listener leaves if `autoDispose`.
- Cubit: in the instance owned by `BlocProvider`; dies when that provider is disposed (here, when the page is popped).
- Bloc: same as Cubit.

**2. The single public mutation API.**
Riverpod's `Notifier`: its public methods, because `state` is only assigned inside the notifier. Cubit: its public methods, which call the protected `emit`. Bloc: `add(event)`. `setState` has none, since the state is private to the `State` object.

**3. Mapping.**
`ref.watch` = `BlocBuilder`, `ref.read` = `context.read`, `ref.listen` = `BlocListener`. `setState` fits none of them cleanly: it is the mutation and the rebuild trigger in one call, with the whole `build` acting as the "watch" and side effects written directly after the await.

**4. Why skip when new `==` old, and what must `CartState` do?**
Equal state means the UI would produce the same output, so notifying wastes rebuilds and can repeat side effects. `CartState` must be immutable, with a new instance for each change, and must have value-based `==` and `hashCode` that compare list contents.

**5. Guards after the await.**
- setState: `mounted`, because the `State` is disposed with the widget and `setState` then throws.
- Riverpod: nothing, because the notifier outlives the page.
- Cubit: `isClosed`, because `BlocProvider` closes it on dispose and `emit` then throws.
- Bloc: `emit.isDone`, because `emit` is scoped to one handler, and the bloc closing ends that handler.

They differ because each guard checks the lifetime of whatever owns the state.

## Comparison table

Non-blank, non-comment lines in each style's own folder and test file. All four also share 391 lines of model, service and widgets. Cubit and Bloc share a further 16-line `BlocSummaryCard`.

| Style | Code T1–T5 | Test code | Files (incl. test) | Strength | Weakness |
|---|---|---|---|---|---|
| setState | 73 | 16 | 2 | No library, fewest concepts | State is trapped in one widget; tests must go through the UI |
| Riverpod | 93 | 36 | 3 | State outlives the page; `select` gives precise rebuilds; widget-free tests | `read` / `watch` / `listen` rules are easy to misuse |
| Cubit | 87 | 57 | 3 | Simple methods; `blocTest` checks exact state sequences | A getter on the cubit is not observable, so everything the UI needs must be in the state |
| Bloc | 142 | 74 | 4 | Named events, full transition log, declarative concurrency | Most boilerplate; an event class per small action |
