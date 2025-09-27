import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../utils/translator.dart';

import 'home_screen.dart';
import 'about_screen.dart';
import 'settings_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const SettingsScreen(),
    const AboutScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0
            ? translate(context, 'home_title')
            : _selectedIndex == 1
                ? translate(context, 'settings')
                : translate(context, 'about')),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.red.shade100),
            onPressed: () {
              authProvider.signOut();
              Navigator.pushReplacementNamed(context, '/signin');
            },
          )
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.green.shade100,
        selectedItemColor: Colors.green.shade800,
        unselectedItemColor: Colors.grey.shade600,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: translate(context, 'home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: translate(context, 'settings'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.info),
            label: translate(context, 'about'),
          ),
        ],
      ),
    );
  }
}
