import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
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
        onTap: (i) {
          // When the user taps the AI chat tab directly (not via scan results
          // push), clear any medicine context so it opens as a general
          // assistant — not pre-loaded with the last scanned medicine.
          if (i == 2 && _currentIndex != 2) {
            context.read<ChatProvider>().setGeneralMode();
          }
          setState(() => _currentIndex = i);
        },
      ),
    );
  }
}
