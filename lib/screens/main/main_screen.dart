import 'package:flutter/material.dart';
import '../../widgets/app_bottom_nav.dart';
import '../scanner/scanner_screen.dart';
import '../history/history_screen.dart';
import '../ai_chat/ai_chat_screen.dart';
import '../profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  static final List<Widget> _tabs = [
    const ScannerScreen(),
    const HistoryScreen(),
    const AiChatScreen(),
    const ProfileScreen(),
  ];

  void switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
