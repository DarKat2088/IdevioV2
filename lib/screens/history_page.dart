import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../controllers/idea_state.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ideaState = Provider.of<IdeaState>(context);
    final historyIdeas = ideaState.historyIdeas;
    final favoritesIdeas = ideaState.favoritesIdeas;

    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    if (historyIdeas.isEmpty) {
      return Center(
        child: Text(
          '🕓 История пуста',
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
      itemCount: historyIdeas.length,
      itemBuilder: (context, index) {
        final idea = historyIdeas[index];
        final isStarred = favoritesIdeas.contains(idea);

        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(1, 1),
                ),
              ],
            ),
            child: Row(
              children: [
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => ideaState.toggleFavorite(idea),
                      icon: Icon(
                        Icons.star,
                        color: isStarred ? Colors.amber : Colors.grey,
                      ),
                    ),
                    IconButton(
                      onPressed: () => ideaState.removeFromHistory(idea),
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}