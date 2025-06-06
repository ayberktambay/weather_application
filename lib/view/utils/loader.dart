import 'package:flutter/material.dart';
class LoaderWidget extends StatelessWidget {
  const LoaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: const Center(child: CircularProgressIndicator(
                strokeAlign: 8,
                strokeCap: StrokeCap.butt,
                color: Color.fromARGB(255, 215, 217, 230),
                backgroundColor: Color.fromARGB(255, 4, 3, 83),
              )));
  }
}