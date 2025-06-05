import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localization/localization.dart';
import 'package:weather_application/providers/language_provider.dart';
class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Settings".i18n(),
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueGrey.shade900,
        elevation: 0,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LanguageCard(),
            ],
          ),
        ),
      ),
    );
  }
}
class LanguageCard extends ConsumerWidget {
  const LanguageCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.blueGrey.shade800,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            Text(
              'Select Language'.i18n(),
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButton<Locale>(
              value: currentLocale,
              dropdownColor: Colors.blueGrey.shade900,
              borderRadius: BorderRadius.circular(10),
              style: const TextStyle(color: Colors.white),
              iconEnabledColor: Colors.white,
              underline: const SizedBox(),
              onChanged: (Locale? newValue) {
                if (newValue != null) {
                  ref.read(localeProvider.notifier).state = newValue;
                }
              },
              items: supportedLocales.map((Locale locale) {
                return DropdownMenuItem<Locale>(
                  value: locale,
                  child: Text(
                    _getLanguageDisplayName(locale),
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _getLanguageDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'tr':
        return 'Türkçe';
      default:
        return locale.toLanguageTag();
    }
  }
}
