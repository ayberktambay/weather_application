import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final backgroundGradientProvider = StateNotifierProvider<BackgroundGradientNotifier, LinearGradient>(
  (ref) => BackgroundGradientNotifier(),
);

class BackgroundGradientNotifier extends StateNotifier<LinearGradient> {
  BackgroundGradientNotifier() : super(_getInitialGradient()) {
    updateGradientBasedOnCurrentTime();
  }

  static LinearGradient _getInitialGradient() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 5 && hour < 12) {
      return const LinearGradient(
        colors: [Color(0xFF87CEEB), Color(0xFFADD8E6)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else if (hour >= 12 && hour < 18) {
      return const LinearGradient(
        colors: [Color(0xFF4A90E2), Color(0xFF50B4EA)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else if (hour >= 18 && hour < 21) {
      return const LinearGradient(
        colors: [Color(0xFFFFA07A), Color(0xFFCD5C5C)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else {
      return const LinearGradient(
        colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    }
  }

  void setGradientBasedOnSunriseSunset(int sunriseTimestamp, int sunsetTimestamp) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final sunrise = sunriseTimestamp;
    final sunset = sunsetTimestamp;

    if (now >= sunrise && now < sunset) {
      final midDayFactor = (now - sunrise) / (sunset - sunrise);
      if (midDayFactor < 0.5) {
        state = const LinearGradient(
          colors: [Color(0xFF87CEEB), Color(0xFFADD8E6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      } else {
        state = const LinearGradient(
          colors: [Color(0xFF4A90E2), Color(0xFF50B4EA)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      }
    } else {
      final currentHour = DateTime.fromMillisecondsSinceEpoch(now * 1000).hour;
      if (currentHour >= 18 || currentHour < 6) {
        if (currentHour >= 18 && currentHour <= 20) {
          state = const LinearGradient(
            colors: [Color(0xFFFFA07A), Color(0xFFCD5C5C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );
        } else {
          state = const LinearGradient(
            colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );
        }
      } else {
        state = const LinearGradient(
          colors: [Color(0xFFADD8E6), Color(0xFFB0E0E6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      }
    }
  }

  void updateGradientBasedOnCurrentTime() {
    state = _getInitialGradient();
  }
}
