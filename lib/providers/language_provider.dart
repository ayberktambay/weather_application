import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Define supported locales
const List<Locale> supportedLocales = [
  Locale('tr', 'TR'),
  Locale('en', 'US'),
];

final localeProvider = StateProvider<Locale>((ref) {
  return const Locale('en', 'US'); 
});

final languageCodeProvider = Provider<String>((ref) {
  return ref.watch(localeProvider).languageCode;
});
