import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localization/localization.dart';
import 'package:weather/constants/app_colors.dart';
import 'package:weather/constants/text_styles.dart';
import 'package:weather/providers/language_provider.dart';

class LanguageSelectionView extends ConsumerWidget {
  const LanguageSelectionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        title: Text(
          "Select a language".i18n(),
          style: w500TS(18, Colors.white),
        ),
      ),
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: AppGradients.blueGradBG,
        child: Consumer(
          builder: (context, ref, child) {
            final currentLocale = ref.watch(localeProvider);
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: kToolbarHeight + 40),
                _buildLanguageOption(
                  context,
                  title: 'Türkçe',
                  subtitle: 'Turkish',
                  isSelected: currentLocale.languageCode == 'tr',
                  onTap: () {
                    ref.read(localeProvider.notifier).state = const Locale('tr');
                  },
                ),
                const SizedBox(height: 12),
                _buildLanguageOption(
                  context,
                  title: 'English',
                  subtitle: 'İngilizce',
                  isSelected: currentLocale.languageCode == 'en',
                  onTap: () {
                    ref.read(localeProvider.notifier).state = const Locale('en');
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.black.withAlpha(100), 
      elevation: 2,
      shadowColor: Colors.black.withAlpha(125),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.white.withAlpha(30)),
      ),
      child: ListTile(
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue : Colors.white,
              ),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
        ),
        trailing: isSelected
            ? const Icon(
                Icons.check_circle,
                color: Colors.blue,
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}