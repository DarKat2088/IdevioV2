import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../controllers/idea_state.dart';
import 'package:share_plus/share_plus.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ideaState = Provider.of<IdeaState>(context); // Получаем состояние через Provider
    final favoritesIdeas = ideaState.favoritesIdeas;

    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    if (favoritesIdeas.isEmpty) {
      return Center(
        child: Text(
          '⭐ Избранное пусто',
          style: GoogleFonts.robotoMono(
            fontSize: 20,
            color: theme.textTheme.bodyLarge!.color,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: favoritesIdeas.length,
      itemBuilder: (context, index) {
        final idea = favoritesIdeas[index];
        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFFB8860B) : Colors.yellow.shade100,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                 IconButton(
                    icon: Icon(
                      Icons.share,
                      color: isDark ? Colors.tealAccent : Colors.indigo,
                    ),
                    onPressed: () {
                      SharePlus.instance.share(
                        ShareParams(
                          text: "🔥 Смотри идею:\n\n$idea\n\n📲 Idevio: https://darkat2088.github.io/IdevioV2/",
                        ),
                      );
                    },
                  ),
                Expanded(
                  child: Text(
                    idea,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.robotoMono(
                      fontSize: 18,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => ideaState.toggleFavorite(idea), 
                  icon: Icon(Icons.star, color: Colors.amber),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}