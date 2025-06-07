import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localization/localization.dart';
import 'package:weather/providers/language_provider.dart';
import 'package:weather/view/home.dart';
import 'package:weather/view/search.dart';
import 'package:weather/view/settings.dart';

class MenuView extends ConsumerStatefulWidget {
  const MenuView({super.key});

  @override
  ConsumerState<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends ConsumerState<MenuView> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);

    List<NavItems> navItems = [
      NavItems(0, "Home", const Icon(Icons.home_outlined), const Icon(Icons.home), const HomeView()),
      NavItems(1, "Search", const Icon(Icons.search_outlined), const Icon(Icons.search), const CityWeatherSearchWidget()),
      NavItems(2, "Settings", const Icon(Icons.settings_outlined), const Icon(Icons.settings), const SettingsView()),
    ];

    return Scaffold(
      body: navItems[currentIndex].path,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 30, 53, 104),
        selectedItemColor: Colors.white,
        unselectedItemColor: const Color.fromARGB(255, 113, 138, 150),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: navItems.map((e) => BottomNavigationBarItem(
          icon: e.disabledIcon!,
          activeIcon: e.activeIcon!,
          label: e.name!.i18n(), 
        )).toList(),
        currentIndex: currentIndex,
        onTap: (value) {
          setState(() {
            currentIndex = value;
          });
        },
      ),
    );
  }
}

class NavItems {
  int index;
  String? name;
  Icon? disabledIcon;
  Icon? activeIcon;
  Widget path;

  NavItems(this.index, this.name, this.disabledIcon, this.activeIcon, this.path);
}
