import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localization/localization.dart';
import 'package:weather/providers/language_provider.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider); // her değişimde rebuild

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Settings".i18n(),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: kToolbarHeight + 20),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: const [
                  LanguageCard(),
                ],
              ),
            ),
          ],
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Select Language'.i18n(),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(100),
            border: Border.all(color: Colors.white.withAlpha(30)),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Locale>(
              isExpanded: true,
              value: currentLocale,
              dropdownColor: Colors.blueGrey.shade900,
              borderRadius: BorderRadius.circular(10),
              style: const TextStyle(color: Colors.white),
              iconEnabledColor: Colors.white,
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
          ),
        ),
      ],
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
