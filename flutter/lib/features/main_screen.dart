import 'package:flutter/material.dart';
import 'package:graduationproject/core/widgets/custom_bottom_nav.dart';
import 'package:graduationproject/features/search_screen/presentation_layer/widgets/searchscreenbody.dart';
import 'package:graduationproject/features/history_screen/presentation_layer/historyscreenview.dart';
import 'package:graduationproject/features/account_screen/presentation_layer/accountscreenview.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // navigator keys لكل tab عشان كل tab يكون عنده history مستقل
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      // لو ضغط على نفس الـ tab يرجع للـ root
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // لو في صفحة داخلية يرجع لها بدل ما يخرج من الـ app
        final canPop = _navigatorKeys[_selectedIndex].currentState?.canPop() ?? false;
        if (canPop) {
          _navigatorKeys[_selectedIndex].currentState?.pop();
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: Stack(
          children: [
            _buildOffstageNavigator(0),
            _buildOffstageNavigator(1),
            _buildOffstageNavigator(2),
          ],
        ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  Widget _buildOffstageNavigator(int index) {
    return Offstage(
      offstage: _selectedIndex != index,
      child: Navigator(
        key: _navigatorKeys[index],
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (_) => _getPage(index),
          );
        },
      ),
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return const SafeArea(child: Searchscreenbody());
      case 1:
        return const SafeArea(child: HistoryView());
      case 2:
        return const SafeArea(child: AccountView());
      default:
        return const SafeArea(child: Searchscreenbody());
    }
  }
}