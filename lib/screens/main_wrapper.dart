import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'plan_screen.dart';
import 'alarm_tab.dart';
import 'profile_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  // List of screens to display


  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      HomeScreen(onTaskPressed: () {
        setState(() {
          _selectedIndex = 1; // Switches tab to PLAN
        });
      }),
      const PlanScreen(),
      const AlarmTab(),
      const ProfileScreen(),
    ];
    return Scaffold(
      // The body changes based on which tab is selected
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.green[50],
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "HOME"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "PLAN"),
          BottomNavigationBarItem(icon: Icon(Icons.access_alarm), label: "ALARM"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "PROFILE"),
        ],
      ),
    );
  }
}