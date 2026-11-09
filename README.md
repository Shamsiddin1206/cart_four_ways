# Cart Four Ways

One shopping cart built four times in one app: `setState`, Riverpod, Cubit and Bloc. Model, pricing rules, checkout service and UI are shared, so only the state handling differs between folders.

Written answers and the comparison table are in [NOTES.md](NOTES.md).

## Run

```
flutter pub get
flutter run -d chrome
flutter test
```

For Android or iOS, run `flutter create .` once to generate the platform folders.
