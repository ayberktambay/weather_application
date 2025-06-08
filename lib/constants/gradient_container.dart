import 'package:flutter/material.dart';
class GradientContainer extends StatelessWidget {
  const GradientContainer({super.key,required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF000020),
                Color(0xFF1A2A55),
                Color(0xFF334F8C),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomScrollView(
                slivers: [
                  SliverList(
                    delegate: SliverChildListDelegate(
                      children,
                    ),
                  ),
                ],
              ),
          ),
        ),
    );
  }
}