
import 'package:flutter/material.dart';

class AppGradients {
  static const LinearGradient dayGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF4A90E2), // Light Blue
      Color(0xFF50B4EA), // Sky Blue
      Color(0xFF67D8EF), // Lighter Blue
    ],
  );

  static const LinearGradient nightGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF000020), // Very Dark Blue
      Color(0xFF1A2A55), // Dark Blue
      Color(0xFF334F8C), // Deep Blue
    ],
  );

  static const LinearGradient twilightGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF4A0033), // Deep Purple
      Color(0xFF8A2387), // Dark Violet
      Color(0xFFE94057), // Reddish Orange
    ],
  );
}