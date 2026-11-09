import 'package:flutter/material.dart';

class SetStateCartPage extends StatelessWidget {
  const SetStateCartPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cart · setState')),
    body: const Center(child: Text('setState')),
  );
}
