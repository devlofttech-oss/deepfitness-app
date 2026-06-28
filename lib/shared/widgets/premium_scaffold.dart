import 'package:flutter/material.dart';

class PremiumScaffold extends StatelessWidget {
  const PremiumScaffold({
    super.key,
    required this.child,
    this.bottomPadding = 24,
    this.scrollController,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  final Widget child;
  final double bottomPadding;
  final ScrollController? scrollController;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(18, 14, 18, bottomPadding),
          child: child,
        ),
      ),
    );
  }
}
