import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/app_bottom_nav.dart';
import '../scanner/scanner_screen.dart';
import '../scanner/prescription_upload_screen.dart';
import '../symptom_checker/symptom_checker_screen.dart';
import '../history/history_screen.dart';
import '../ai_chat/ai_chat_screen.dart';
import '../profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // Build tabs dynamically to avoid lifecycle issues
  List<Widget> get _tabs => [
    const ScannerScreen(),
    const PrescriptionUploadScreen(),
    const SymptomCheckerScreen(),
    const HistoryScreen(),
    const AiChatScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _fadeAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn),
    );
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void switchTab(int index) {
    if (index != _currentIndex) {
      _fadeCtrl.forward(from: 0.0);
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnim,
        child: IndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) {
          if (i == 4 && _currentIndex != 4) {
            context.read<ChatProvider>().setGeneralMode();
          }
          switchTab(i);
        },
      ),
    );
  }
}
