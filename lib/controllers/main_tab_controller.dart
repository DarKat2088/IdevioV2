import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/falling_emojis.dart';
import '../screens/idea_generator_screen.dart';
import '../screens/favorites_page.dart';
import '../screens/history_page.dart';
import '../screens/login_screen.dart';
import 'package:provider/provider.dart';
import '../controllers/idea_state.dart';
import '../screens/profile_screen.dart';

class MainTabController extends StatefulWidget {
  final VoidCallback toggleTheme;
  final ThemeMode themeMode;
  final void Function(User user)? onLoginCallback; 

  const MainTabController({
    Key? key,
    required this.toggleTheme,
    required this.themeMode,
    this.onLoginCallback, 
  }) : super(key: key);

  @override
  State<MainTabController> createState() => _MainTabControllerState();
}

class _MainTabControllerState extends State<MainTabController>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ValueNotifier<bool> showFallingEmojis = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    showFallingEmojis.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    final isLight = widget.themeMode == ThemeMode.light;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isLight ? Color.fromARGB(255, 43, 53, 158) :Colors.tealAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isLight ? Colors.amberAccent :Color(0xFF00695C),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CosmicAnimatedBackground(themeMode: widget.themeMode),
        ValueListenableBuilder<bool>(
          valueListenable: showFallingEmojis,
          builder: (context, show, _) =>
              show ? FallingEmojis(count: 20, enabled: true) : const SizedBox.shrink(),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              'Idevio',
              style: GoogleFonts.robotoMono(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                shadows: const [Shadow(offset: Offset(2, 2), color: Colors.black26, blurRadius: 4)],
              ),
            ),
            centerTitle: true,
            actions: [
              // Смена темы
              Tooltip(
                message: widget.themeMode == ThemeMode.light
                    ? "Включить тёмную тему"
                    : "Включить светлую тему",
                child: IconButton(
                  icon: Icon(
                    widget.themeMode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode,
                    color: widget.themeMode == ThemeMode.light ? Colors.black87 : Colors.amber,
                  ),
                  onPressed: widget.toggleTheme,
                ),
              ),
              // Падающие эмодзи
              ValueListenableBuilder<bool>(
                valueListenable: showFallingEmojis,
                builder: (context, show, _) {
                  return Tooltip(
                    message: show ? "Выключить падающие эмодзи" : "Включить падающие эмодзи",
                    child: IconButton(
                      icon: Icon(
                        show ? Icons.auto_awesome : Icons.celebration,
                        color: widget.themeMode == ThemeMode.light
                            ? (show ? const Color.fromARGB(255, 43, 53, 158) : Colors.black87)
                            : (show ? Colors.tealAccent : Colors.white70),
                      ),
                      onPressed: () => showFallingEmojis.value = !show,
                    ),
                  );
                },
              ),
              // Профиль
              Tooltip(
                message: "Профиль",
                child: StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snapshot) {
                    final logged = snapshot.data != null;
                    final iconColor = widget.themeMode == ThemeMode.light
                        ? (logged
                            ? const Color.fromARGB(255, 43, 53, 158)
                            : Colors.black87)
                        : (logged ? Colors.tealAccent : Colors.white70);

                    return IconButton(
                      icon: Icon(Icons.person, color: iconColor),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileScreen(
                              themeMode: widget.themeMode,
                              toggleTheme: widget.toggleTheme,
                             ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor:
                  widget.themeMode == ThemeMode.light ? Colors.redAccent : Colors.tealAccent,
              labelColor: widget.themeMode == ThemeMode.light ? Colors.redAccent : Colors.tealAccent,
              unselectedLabelColor:
                  widget.themeMode == ThemeMode.light ? Colors.black87 : Colors.white70,
              labelStyle:
                  GoogleFonts.robotoMono(fontSize: 18, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: "Главная"),
                Tab(text: "Избранное"),
                Tab(text: "История"),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              IdeaGeneratorScreen(themeMode: widget.themeMode),
              FavoritesPage(),
              HistoryPage(),
            ],
          ),
        ),
      ],
    );
  }
}