import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      NavItems(0, "Home",  const HomeView()),
      NavItems(1, "Settings", const SettingsView()),
      NavItems(2, "Search", const CityWeatherSearchWidget()),
    ];

    return Scaffold(
      backgroundColor:  const Color.fromARGB(255, 53, 76, 126),
        floatingActionButton: Container(
          decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(360),
            gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
           Colors.white,
           const Color.fromARGB(255, 230, 230, 230),
            ],
          ), 
         ), 
                  child: IconButton(
                          onPressed: (){
                            currentIndex = 2;
                            setState(() { });
                          },
                          icon: const Icon(Icons.search,size: 30,color:  Color.fromARGB(255, 9, 37, 112),),
                        ),
      ),
      extendBodyBehindAppBar: false,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      body: navItems[currentIndex].path,
      bottomNavigationBar: BottomAppBar(
                padding: const EdgeInsets.all(4),
                color: const Color.fromARGB(255, 30, 53, 104),
              shape: const CircularNotchedRectangle(),
              notchMargin: 2.0,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  IconButton(
                    icon: Column(
                      children: [
                        Icon(currentIndex == 0 ? Icons.home : Icons.home_outlined,size: 30,color: Colors.white,),
                    
                      ],
                    ),
                    onPressed: () {
                      setState(() { currentIndex = 0;});
                      },
                  ),
                
                  const SizedBox(width: 48.0), 
                    IconButton(
                    icon: Column(
                      children: [
                        Icon(currentIndex == 1 ? Icons.settings : Icons.settings_outlined,size:30,color: Colors.white,),
                      
                      ],
                    ),
                    onPressed: () {
                      currentIndex = 1;
                      setState(() {});
                      },
                  ),
               
                ],
              ),
      ),
    );
  }
}

class NavItems {
  int index;
  String? name;
  Widget path;

  NavItems(this.index, this.name,this.path);
}
