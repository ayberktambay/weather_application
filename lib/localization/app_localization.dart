import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  AppLocalizations(this.locale);
  final Locale locale;
  late Map<String, String> _localizedStrings;

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  Future<bool> load() async {
    var jsonString = await rootBundle.loadString('assets/language/${locale.languageCode}_${locale.countryCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings = jsonMap.map((key, value) {
    return MapEntry(key, value.toString());
    });
    return true;
  }

  String translate(String key) => _localizedStrings[key]!;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  static var lastLoadedLocale;
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['tr', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    var localizations = AppLocalizations(locale);
    await localizations.load();
    lastLoadedLocale = AppLocalizations(locale); 
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) {
    return false;
  }
}

void printLoadedLocale() {
  if (_AppLocalizationsDelegate.lastLoadedLocale != null) {
 
  } else {
  
  }
}
