import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import '../services/ai_service.dart';
import '../widgets/animated_rainbow_text.dart';
import '../services/idea_service.dart';
import '../controllers/idea_state.dart';
import '../utils/storage.dart'; 
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
class IdeaGeneratorScreen extends StatefulWidget {
  final ThemeMode themeMode;

  const IdeaGeneratorScreen({Key? key, required this.themeMode}) : super(key: key);

  @override
  _IdeaGeneratorScreenState createState() => _IdeaGeneratorScreenState();
}
enum GenerateMode { local, ai }
class _IdeaGeneratorScreenState extends State<IdeaGeneratorScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final StreamSubscription<User?> _authSub;
  User? _user;
  final AiRenderService aiService = AiRenderService();
  String selectedCategory = "Категории";
  bool isDropdownOpen = false;
  bool isGenerating = false;
  String? currentIdea;
  String? expandedCategory;
  GenerateMode selectedMode = GenerateMode.local;

  late final AnimationController _ideaController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  late final AnimationController _waveController;
  late final Animation<double> _waveAnimation;
  late final AnimationController _starController;

  final player = AudioPlayer();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    aiService.generateIdea("warmup").catchError((_) {});
    
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;

      setState(() {
        _user = user;
      });
    });

    IdeaService.init();


    _ideaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ideaController, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_ideaController);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _waveAnimation = Tween<double>(begin: 0, end: 20).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeOut),
    );

    _starController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      lowerBound: 0.8,
      upperBound: 1.18,
    );
  }

  @override
  void dispose() {
     _authSub.cancel();
    _ideaController.dispose();
    _waveController.dispose();
    _starController.dispose();
    super.dispose();
  }

  // ====================
  // Генерация идеи
  // ====================
  Future<void> generateIdea() async {
    final user = FirebaseAuth.instance.currentUser;
    final ideaState = Provider.of<IdeaState>(context, listen: false);
    try {
      player.play(
        AssetSource('sounds/cartoon-game-damage-alert-ni-sound-1-00-03.mp3'),
      );
    } catch (e) {}

    setState(() {
      isGenerating = true;
      currentIdea = null;
    });

    try {
      if (selectedMode == GenerateMode.local) {
        await Future.delayed(const Duration(milliseconds: 2000));
      }

      String idea;

      if (selectedMode == GenerateMode.local) {
        idea = IdeaService.getIdea(selectedCategory);
      } else {
        idea = await aiService.generateIdea(
          "$selectedCategory ${DateTime.now().millisecondsSinceEpoch}"
        );
      }

      idea = idea.trim();

      if (idea.isEmpty) {
        idea = "AI вернул пустой ответ";
      }
      ideaState.addToHistory(idea);
      setState(() {
        currentIdea = idea;
        isGenerating = false;
      });

      _ideaController.forward(from: 0);

    } catch (e) {
      setState(() {
        currentIdea = "Ошибка генерации";
        isGenerating = false;
      });

      _ideaController.forward(from: 0);
    }
  }

  void toggleFavoriteCurrentIdea() {
    if (currentIdea == null) return;

    final ideaState = Provider.of<IdeaState>(context, listen: false);
    ideaState.toggleFavorite(currentIdea!);

    if (!ideaState.favoritesIdeas.contains(currentIdea)) {
      _waveController.forward(from: 0);
    }

    _starController.forward(from: 0);
  }

  // ====================
  // Overlay уведомление "скопировано"
  // ====================
  Future<void> _showCopiedOverlay(BuildContext ctx) async {
    final overlay = Overlay.of(ctx);
    if (overlay == null) return;

    late OverlayEntry entry;
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 260),
    );

    final animation =
        CurvedAnimation(parent: controller, curve: Curves.easeOutCubic);

    entry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 68,
        left: 0,
        right: 0,
        child: FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF9E7),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.25),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Text(
                  '✨ Идея скопирована!',
                  style: GoogleFonts.robotoMono(
                    color: Colors.amber.shade700,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    controller.forward();
    await Future.delayed(const Duration(milliseconds: 900));
    await controller.reverse();
    entry.remove();
    controller.dispose();
  }

  // ====================
  // Dropdown категорий
  // ====================
  Widget buildCategoryDropdown() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF014F5B) : const Color.fromARGB(255, 241, 235, 200);
    final textColor = isDark ? Colors.tealAccent.shade100 : Colors.indigo[900];

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () => setState(() => isDropdownOpen = !isDropdownOpen),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedCategory,
                    style: GoogleFonts.robotoMono(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    isDropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: textColor,
                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              constraints: BoxConstraints(
                maxHeight: isDropdownOpen ? 32 * 6.0 : 0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: IdeaService.getCategories().toList().asMap().entries.map((entry) {
                    final idx = entry.key;
                    final cat = entry.value;

                    return TweenAnimationBuilder<Offset>(
                      tween: Tween<Offset>(
                        begin: const Offset(0, -0.5),
                        end: Offset.zero,
                      ),
                      duration: const Duration(milliseconds: 300),
                      curve: Interval(idx * 0.05, 1.0, curve: Curves.easeOut),
                      builder: (context, offset, child) {
                        return Transform.translate(
                          offset: Offset(0, offset.dy * 36),
                          child: child,
                        );
                      },
                      child: AnimatedOpacity(
                        opacity: isDropdownOpen ? 1 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: InkWell(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () => setState(() {
                            selectedCategory = cat;
                            isDropdownOpen = false;
                          }),
                          child: Container(
                            height: 32,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              cat,
                              style: GoogleFonts.robotoMono(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final ideaState = Provider.of<IdeaState>(context);

    Widget buildInitialText() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 22),
        decoration: BoxDecoration(
          color: isDark ? const Color.fromARGB(255, 3, 78, 66) : Colors.yellow.shade100,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: AnimatedRainbowText(
          text: "Нажмите снизу, чтобы начать!",
          style: GoogleFonts.robotoMono(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          themeMode: widget.themeMode,
        ),
      );
    }
    final isGuest = _user == null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isGenerating)
              AnimatedTextKit(
                animatedTexts: [
                  TypewriterAnimatedText(
                    'Генерация идеи...',
                    textStyle: GoogleFonts.robotoMono(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: widget.themeMode == ThemeMode.light
                          ? Color.fromARGB(255, 43, 53, 158)
                          : Colors.tealAccent.shade200,
                    ),
                    speed: const Duration(milliseconds: 100),
                  ),
                ],
                totalRepeatCount: 1,
              )
            else if (currentIdea != null)
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.share,
                          color: widget.themeMode == ThemeMode.light
                              ? Colors.indigo[900]
                              : Colors.tealAccent,
                        ),
                        onPressed: () async {
                          if (currentIdea == null) return;

                          final idea = currentIdea!;

                          final text = "🔥 Смотри, какая идея у меня сгенерировалась:\n\n"
                              "$idea\n\n"
                              "✨ Попробуй и ты!\n\n";

                          const appLink =
                              "📲 Сгенерировано в Idevio: https://darkat2088.github.io/IdevioV2/";

                           final fullText = "$text$appLink";

                            await SharePlus.instance.share(
                              ShareParams(text: fullText),
                            );
                        },             
                      ),
                      GestureDetector(
                        onTap: () async {
                          if (currentIdea == null) return;
                          await Clipboard.setData(ClipboardData(text: currentIdea!));
                          await _showCopiedOverlay(context);
                        },
                        child: SizedBox(
                          width: 280,
                          child: Text(
                            currentIdea ?? "",
                            textAlign: TextAlign.center,
                            softWrap: true,
                            maxLines: null,
                            style: GoogleFonts.robotoMono(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: widget.themeMode == ThemeMode.light
                                  ? const Color.fromARGB(255, 43, 53, 158)
                                  : Colors.cyanAccent.shade200,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                              maxWidth: 40,
                              maxHeight: 40,
                            ),
                            child: AnimatedBuilder(
                              animation: _waveController,
                              builder: (context, child) {
                                final waveValue = _waveAnimation.value;
                                return Center(
                                  child: Container(
                                    width: 30 + waveValue,
                                    height: 30 + waveValue,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: ideaState.favoritesIdeas.contains(currentIdea)
                                          ? Colors.redAccent.withOpacity(
                                              (1 - waveValue / 20).clamp(0.0, 0.25))
                                          : Colors.transparent,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          ScaleTransition(
                            scale: _starController,
                            child: GestureDetector(
                              onTap: toggleFavoriteCurrentIdea,
                              child: Icon(
                                ideaState.favoritesIdeas.contains(currentIdea)
                                    ? Icons.star
                                    : Icons.star_border,
                                color: widget.themeMode == ThemeMode.light
                                    ? Colors.redAccent
                                    : (ideaState.favoritesIdeas.contains(currentIdea)
                                        ? Colors.amber
                                        : Colors.grey[400]),
                                size: 30,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else
              buildInitialText(),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: isGenerating ? null : generateIdea,
              icon: Icon(
                Icons.auto_awesome,
                color: isDark ? Colors.tealAccent : Colors.indigo[900],
                size: 28,
              ),
              label: Text(
                "Сгенерировать",
                style: GoogleFonts.robotoMono(
                  color: isDark ? Colors.tealAccent : Colors.indigo[900],
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? const Color(0xFF00695C)
                    : const Color.fromARGB(255, 240, 235, 220),
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                shadowColor: isDark
                    ? Colors.tealAccent.withOpacity(0.35)
                    : Colors.amberAccent.withOpacity(0.6),
                elevation: 10,
              ),
            ),
            const SizedBox(height: 30),
            buildCategoryDropdown(),
            Container(
              width: 180,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF014F5B)
                    : const Color.fromARGB(255, 241, 235, 200),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          selectedMode = GenerateMode.local;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selectedMode == GenerateMode.local
                              ? (isDark ? Colors.tealAccent.withOpacity(0.3) : Colors.indigo.withOpacity(0.2))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            "LOCAL",
                            style: GoogleFonts.robotoMono(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: selectedMode == GenerateMode.local
                                  ? (isDark ? Colors.tealAccent : Colors.indigo[900])
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          selectedMode = GenerateMode.ai;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selectedMode == GenerateMode.ai
                              ? (isDark ? Colors.tealAccent.withOpacity(0.3) : Colors.indigo.withOpacity(0.2))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            "AI",
                            style: GoogleFonts.robotoMono(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: selectedMode == GenerateMode.ai
                                  ? (isDark ? Colors.tealAccent : Colors.indigo[900])
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}