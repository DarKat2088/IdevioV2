import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:idea_generator_app_v2/firebase_options.dart';
import '../controllers/main_tab_controller.dart';
import '../controllers/idea_state.dart';

class IdevioApp extends StatefulWidget {
  const IdevioApp({Key? key}) : super(key: key);

  @override
  _IdevioAppState createState() => _IdevioAppState();
}

class _IdevioAppState extends State<IdevioApp> {
  ThemeMode themeMode = ThemeMode.light;
  bool _initialized = false;
  late IdeaState _ideaState;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    final prefs = await SharedPreferences.getInstance();
    themeMode = (prefs.getBool('isDarkTheme') ?? false) ? ThemeMode.dark : ThemeMode.light;

    // Создаем IdeaState один раз (без пользователя)
    final firebaseUser = FirebaseAuth.instance.currentUser;
    _ideaState = IdeaState(user: firebaseUser);

    setState(() {
      _initialized = true;
    });
  }

  void toggleTheme() async {
    setState(() {
      themeMode = themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkTheme', themeMode == ThemeMode.dark);
  }

  // Вызывается после успешного логина
  void onLogin(User user) {
    _ideaState.setUser(user);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return ChangeNotifierProvider<IdeaState>.value(
      value: _ideaState,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Idevio',
        themeMode: themeMode,
        theme: ThemeData(
          brightness: Brightness.light,
          primaryColor: const Color.fromARGB(255, 115, 223, 199),
          scaffoldBackgroundColor: Colors.deepPurple[50],
          textTheme: GoogleFonts.robotoMonoTextTheme().apply(
            bodyColor: Colors.black87,
            displayColor: Colors.black87,
          ),
          appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              elevation: 4),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.indigo,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 10,
            ),
          ),
          cardColor: Colors.yellow.shade100,
          iconTheme: const IconThemeData(color: Colors.indigo),
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: Colors.tealAccent,
          scaffoldBackgroundColor: Colors.grey[900],
          textTheme: GoogleFonts.robotoMonoTextTheme()
              .apply(bodyColor: Colors.white70, displayColor: Colors.white70),
          appBarTheme: AppBarTheme(
              backgroundColor: Colors.grey[850],
              foregroundColor: Colors.white70,
              elevation: 4),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 10,
            ),
          ),
          cardColor: Colors.grey[800],
          iconTheme: const IconThemeData(color: Colors.tealAccent),
        ),
        home: MainTabController(
          themeMode: themeMode,
          toggleTheme: toggleTheme,
          onLoginCallback: onLogin, // передаем колбэк
        ),
      ),
    );
  }
}