import 'package:flutter/material.dart';

class HeaderContainer extends StatelessWidget {
  const HeaderContainer({
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.border,
    required this.child,
  });

  final EdgeInsets padding;
  final BoxBorder? border;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: border ??
            Border(
              top: BorderSide(color: Colors.grey.withOpacity(0.1)),
            ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 10),
            spreadRadius: -10,
            blurRadius: 10,
          ),
        ],
      ),
      child: child,
    );
  }
}
