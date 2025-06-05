import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localization/localization.dart';
import 'package:weather_application/localization/app_localization.dart';
import 'package:weather_application/providers/language_provider.dart';
import 'package:weather_application/service/app_config_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:weather_application/view/menu.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppConfigService().loadConfig();
   runApp(
    const ProviderScope( 
      child: MainApp(),
    ),
  );
}

class MainApp extends ConsumerWidget { // Change to ConsumerWidget
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) { 
    LocalJsonLocalization.delegate.directories = ['assets/language'];
    final locale = ref.watch(localeProvider);
    return  Consumer(
     builder: (context, ref, _) {
      return MaterialApp(
          localizationsDelegates: [
            LocalJsonLocalization.delegate, 
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            AppLocalizations.delegate,
          ],
          supportedLocales: supportedLocales, 
          locale: Locale(locale.languageCode), 
          debugShowCheckedModeBanner: false,
          home: Builder(
            builder: (BuildContext builderContext) {
              return MenuView();
            },
          ),
        );
      }
    );
  }
}
