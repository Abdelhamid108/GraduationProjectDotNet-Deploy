import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
  BottomNavigationBarItem(
    icon: Icon(Icons.home),
    label: 'الرئيسية',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.history),
    label: 'السجل',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.account_circle),
    label: 'الملف الشخصي',
  ),
],
      currentIndex: currentIndex,
      selectedItemColor: const Color(0xFF248DBC),
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      elevation: 8,
    );
  }
}