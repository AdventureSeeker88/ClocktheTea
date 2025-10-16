import 'package:flutter/material.dart';
import 'Home/HomeScreen.dart';
import 'Profile/ProfileScreen.dart';
import 'Search/SearchScreen.dart';
import 'Tea/MyTeaScreen.dart';
import 'Widgets/bottom_nav_bar.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove bottomNavigationBar
      body: Stack(
        children: [
          // Pages
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              HomeScreen(),
              SearchScreen(),
              MyTeasScreen(),
              ProfileScreen()
            ],
          ),

          // Bottom Nav (stacked & floating)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppBottomNavBar(
              initialIndex: _currentIndex,
              onTabSelected: _onTabSelected,
            ),
          ),
        ],
      ),
    );
  }
}
