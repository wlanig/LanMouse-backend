import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'touchpad_page.dart';
import 'connection_page.dart';
import 'user_center_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    TouchpadPage(),
    ConnectionPage(),
    UserCenterPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppTheme.cardColor,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.touch_app_outlined),
              activeIcon: Icon(Icons.touch_app),
              label: '触控板',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.wifi_find_outlined),
              activeIcon: Icon(Icons.wifi_find),
              label: '连接',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: '我的',
            ),
          ],
        ),
      ),
    );
  }
}
