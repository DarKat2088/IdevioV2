import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/login_screen.dart';
import '../screens/profile_edit_screen.dart';
import '../services/profile_service.dart';
import '../widgets/cosmic_background.dart';

class ProfileScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback toggleTheme;

  const ProfileScreen({
    super.key,
    required this.themeMode,
    required this.toggleTheme,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _service = ProfileService();

  Future<void> _openEdit(User user) async {
    await showGeneralDialog(
      context: context,
      barrierLabel: "Edit Profile",
      barrierDismissible: true,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: ProfileEditScreen(
              themeMode: widget.themeMode,
              user: user,
            ),
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
    );
  }

  Widget _button({
    required String text,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeMode == ThemeMode.dark;
    final primary = isDark ? Colors.tealAccent : Colors.indigo.shade900;

    final user = FirebaseAuth.instance.currentUser;
    final isGuest = user == null;

    final name = isGuest ? "Гость" : (user.displayName ?? "User");

    return Stack(
      children: [
        CosmicAnimatedBackground(themeMode: widget.themeMode),

        Scaffold(
          backgroundColor: Colors.transparent,

          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: primary),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: primary.withOpacity(0.2),
                  child: Icon(Icons.person, size: 50, color: primary),
                ),

                const SizedBox(height: 12),

                Text(
                  name,
                  style: TextStyle(
                    color: primary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 18),

                if (!isGuest)
                  _button(
                    text: "Редактирование профиля",
                    color: primary,
                    onTap: () async {
                      await _openEdit(user!);
                    },
                  ),

                if (!isGuest)
                  _button(
                    text: "Управление аккаунтом",
                    color: primary,
                    onTap: () {
                      final user = FirebaseAuth.instance.currentUser;

                      showDialog(
                        context: context,
                        builder: (dialogContext) {
                          return AlertDialog(
                            title: const Text("Управление аккаунтом"),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.email, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        user?.email ?? "Нет email",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // СМЕНА ПАРОЛЯ
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.lock_reset),
                                  title: const Text("Сменить пароль"),
                                  onTap: () async {
                                     final user = FirebaseAuth.instance.currentUser;

                                      print("EMAIL: ${user?.email}");
                                      print("UID: ${user?.uid}");
                                      print("ANON: ${user?.isAnonymous}");

                                    try {
                                      await FirebaseAuth.instance.sendPasswordResetEmail(
                                        email: user!.email!,
                                      );

                                      Navigator.pop(dialogContext);

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Письмо для смены пароля отправлено (Проверь СПАМ)"),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Ошибка: $e")),
                                      );
                                    }
                                  },
                                ),

                                // УДАЛЕНИЕ АККАУНТА
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.delete, color: Colors.red),
                                  title: const Text(
                                    "Удалить аккаунт",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  onTap: () {
                                    Navigator.pop(dialogContext);

                                    showDialog(
                                      context: context,
                                      builder: (confirmContext) {
                                        return AlertDialog(
                                          title: const Text("Удаление аккаунта"),
                                          content: const Text(
                                            "Вы уверены? Это действие нельзя отменить.",
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(confirmContext),
                                              child: const Text("Отмена"),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                Navigator.pop(confirmContext);

                                                try {
                                                  await user?.delete();

                                                  Navigator.pushAndRemoveUntil(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) => ProfileScreen(
                                                          themeMode: ThemeMode.dark, 
                                                          toggleTheme: () {
                                                          },
                                                        ),
                                                      ),
                                                      (route) => false,
                                                    );
                                                } catch (e) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text("Ошибка: $e")),
                                                  );
                                                }
                                              },
                                              child: const Text(
                                                "Удалить",
                                                style: TextStyle(color: Colors.red),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: const Text("Закрыть"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),

                _button(
                  text: isGuest ? "Войти" : "Выйти",
                  color: isGuest ? primary : Colors.red,
                  onTap: () async {
                      if (isGuest) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LoginScreen(
                              themeMode: widget.themeMode,
                              onLogin: (user) {
                                setState(() {});
                              },
                            ),
                          ),
                        );
                      } else {
                        await _service.signOut();
                        setState(() {});
                      }
                    },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}