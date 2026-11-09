import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bloc/cart_page_bloc.dart';
import 'cubit/cart_page_cubit.dart';
import 'riverpod/cart_page_riverpod.dart';
import 'setstate/cart_page_setstate.dart';

void main() {
  Bloc.observer = TransitionLogger();
  runApp(const ProviderScope(child: CartFourWaysApp()));
}

/// Prints currentState -> event -> nextState for every Bloc transition.
class TransitionLogger extends BlocObserver {
  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    debugPrint('[${bloc.runtimeType}] $transition');
  }
}

class CartFourWaysApp extends StatelessWidget {
  const CartFourWaysApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Cart Four Ways',
    theme: ThemeData(colorSchemeSeed: Colors.teal),
    home: const HomePage(),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _pages = <(String, Widget)>[
    ('setState', SetStateCartPage()),
    ('Riverpod', RiverpodCartPage()),
    ('Cubit', CubitCartPage()),
    ('Bloc', BlocCartPage()),
  ];

  Future<void> _open(BuildContext context, Widget page) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page));
    // Banners belong to the app-wide messenger, so clear any left behind.
    if (context.mounted) ScaffoldMessenger.of(context).clearMaterialBanners();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('One Cart, Four Ways')),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (label, page) in _pages)
            Padding(
              padding: const EdgeInsets.all(8),
              child: FilledButton(
                onPressed: () => _open(context, page),
                child: Text(label),
              ),
            ),
        ],
      ),
    ),
  );
}
