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
