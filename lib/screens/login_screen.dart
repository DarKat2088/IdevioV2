import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/cosmic_background.dart';

class LoginScreen extends StatefulWidget {
  final Function(User user) onLogin;
  final ThemeMode themeMode;

  const LoginScreen({
    Key? key,
    required this.onLogin,
    required this.themeMode,
  }) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _showPassword = false;

  String? _emailError;
  String? _passwordError;

  void _showMessage(String message) {
    final isDark = widget.themeMode == ThemeMode.dark;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isDark ? Color(0xFF00695C) :Color.fromARGB(255, 240, 235, 220),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark ? Colors.tealAccent : Colors.indigo[900],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _emailError = null;
      _passwordError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (!_isLogin && password.length < 6) {
      setState(() {
        _passwordError = 'Пароль должен быть минимум 6 символов';
        _isLoading = false;
      });
      return;
    }
    try {
      UserCredential userCredential;
      if (_isLogin) {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email, 
          password: password
        );
      } else {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, 
          password: password
        );
        _showMessage('Регистрация успешна!');
      }
       widget.onLogin(userCredential.user!);
       Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          _emailError = 'Этот email уже зарегистрирован.';
          break;
        case 'invalid-email':
          _emailError = 'Неверный формат email.';
          break;
        case 'weak-password':
          _passwordError = 'Пароль слишком короткий (минимум 6 символов).';
          break;
        case 'user-not-found':
          _emailError = 'Пользователь не найден.';
          break;
        case 'wrong-password':
          _passwordError = 'Неверный пароль.';
          break;
        default:
          _passwordError = 'Произошла ошибка';
      }
      setState(() {});
    } catch (_) {
      _passwordError = 'Произошла ошибка';
      setState(() {});
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.themeMode == ThemeMode.dark;
    final Color cardColor = isDark ? const Color.fromARGB(255, 3, 78, 66) : Colors.yellow.shade100;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          CosmicAnimatedBackground(themeMode: widget.themeMode),

          Positioned(
            top: 10,
            left: 10,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Card(
                  color: cardColor,
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isLogin ? 'Вход' : 'Регистрация',
                          style: GoogleFonts.robotoMono(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.tealAccent : Colors.indigo[900],
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _emailController,
                          autofillHints: const [AutofillHints.email],
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: isDark ? Colors.grey[800] : Colors.white,
                            errorText: _emailError,
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: !_showPassword,
                          decoration: InputDecoration(
                            labelText: 'Пароль',
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: isDark ? Colors.grey[800] : Colors.white,
                            errorText: _passwordError,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPassword ? Icons.visibility : Icons.visibility_off,
                                color: isDark ? Colors.tealAccent : Colors.indigo[900],
                              ),
                              onPressed: () => setState(() => _showPassword = !_showPassword),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _submit,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    backgroundColor: isDark
                                        ? const Color(0xFF00695C)
                                        : const Color.fromARGB(255, 240, 235, 220),
                                    foregroundColor: isDark ? Colors.tealAccent : Colors.indigo[900],
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                    elevation: 6,
                                  ),
                                  child: Text(
                                    _isLogin ? 'Войти' : 'Зарегистрироваться',
                                    style: GoogleFonts.robotoMono(fontSize: 18),
                                  ),
                                ),
                              ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => setState(() {
                            _isLogin = !_isLogin;
                            _passwordError = null;
                            _emailError = null;
                          }),
                          child: Text(
                            _isLogin
                                ? 'Нет аккаунта? Зарегистрироваться'
                                : 'Уже есть аккаунт? Войти',
                            style: GoogleFonts.robotoMono(
                              fontSize: 14,
                              color: isDark ? Colors.tealAccent : Colors.indigo[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}