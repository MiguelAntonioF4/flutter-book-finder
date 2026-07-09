import 'package:flutter/material.dart';

import '../models/book.dart';
import '../routes.dart';
import '../services/favorites_service.dart';
import '../widgets/book_card.dart';
import '../widgets/state_views.dart';

/// Tela de favoritos: lista os livros salvos localmente e permite
/// remover (com opção de desfazer via SnackBar).
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late List<Book> _favorites;

  @override
  void initState() {
    super.initState();
    _favorites = FavoritesService.instance.getFavorites();
  }

  Future<void> _openDetails(Book book) async {
    await Navigator.of(context).pushNamed(AppRoutes.details, arguments: book);
    // O livro pode ter sido removido dos favoritos na tela de detalhes.
    if (mounted) {
      setState(() => _favorites = FavoritesService.instance.getFavorites());
    }
  }

  Future<void> _removeFavorite(Book book) async {
    final removedIndex = _favorites.indexOf(book);
    setState(() => _favorites.removeWhere((b) => b.workKey == book.workKey));
    await FavoritesService.instance.removeFavorite(book.workKey);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${book.title}" removido dos favoritos'),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () async {
            await FavoritesService.instance.toggleFavorite(book);
            if (!mounted) return;
            setState(() {
              final index = removedIndex.clamp(0, _favorites.length);
              _favorites.insert(index, book);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus Favoritos')),
      body: _favorites.isEmpty
          ? const EmptyView(
              icon: Icons.favorite_border_rounded,
              message: 'Você ainda não tem livros favoritos',
              subtitle: 'Toque no coração de um livro na busca para salvá-lo aqui.',
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 16, top: 8),
              itemCount: _favorites.length,
              itemBuilder: (context, index) {
                final book = _favorites[index];
                return BookCard(
                  book: book,
                  onTap: () => _openDetails(book),
                  isFavorite: true,
                  onFavoriteToggle: () => _removeFavorite(book),
                );
              },
            ),
    );
  }
}
