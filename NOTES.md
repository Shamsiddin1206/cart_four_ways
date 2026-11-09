# Lab notes: One Cart, Four Ways

## Part 1: Shared code

**Why is `CartLine` immutable with `copyWith` instead of a mutable `qty`?**
A new object per change means old and new state can be compared, undo snapshots stay correct, and nobody can change a line behind the state holder's back. Only `setState` would still "work" with mutation, because it rebuilds whatever the data looks like. That is the trap: the code seems fine until it moves to Riverpod, Cubit or Bloc, where the old and new state are the same object, `==` is true, and the UI silently stops updating. An undo stack would also hold references to objects that have since changed.

**Why does `CartBody` take callbacks?**
So it knows nothing about state management and the same widget serves all four styles. Importing a provider or bloc would tie it to one style. It is also testable by passing plain data.
