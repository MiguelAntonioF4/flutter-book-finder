import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/book.dart';

/// Guarda os livros favoritos no armazenamento local do dispositivo
/// (SharedPreferences) para que a lista sobreviva a um fechamento do app.
///
/// É implementado como singleton com um cache em memória: [init] é chamado
/// uma única vez em `main()`, antes de `runApp`, e depois disso todas as
/// leituras (`isFavorite`, `getFavorites`) são síncronas — as telas não
/// precisam de `FutureBuilder` nem de um gerenciador de estado externo,
/// só chamam `setState` depois de `toggleFavorite`/`removeFavorite`.
class FavoritesService {
  FavoritesService._internal();
  static final FavoritesService instance = FavoritesService._internal();

  static const _storageKey = 'favorite_books_v1';

  final Map<String, Book> _favorites = {};
  SharedPreferences? _prefs;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getStringList(_storageKey) ?? const [];

    for (final item in raw) {
      try {
        final map = jsonDecode(item) as Map<String, dynamic>;
        final book = Book.fromJson(map);
        _favorites[book.workKey] = book;
      } catch (_) {
        // Ignora entradas corrompidas em vez de derrubar o app inteiro.
      }
    }
    _initialized = true;
  }

  /// Lista de favoritos ordenada por título.
  List<Book> getFavorites() {
    final list = _favorites.values.toList();
    list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return list;
  }

  bool isFavorite(String workKey) => _favorites.containsKey(workKey);

  /// Alterna o estado de favorito de [book] e persiste a mudança.
  /// Retorna `true` se o livro passou a ser favorito, `false` se foi removido.
  Future<bool> toggleFavorite(Book book) async {
    final willBeFavorite = !_favorites.containsKey(book.workKey);
    if (willBeFavorite) {
      _favorites[book.workKey] = book;
    } else {
      _favorites.remove(book.workKey);
    }
    await _persist();
    return willBeFavorite;
  }

  Future<void> removeFavorite(String workKey) async {
    _favorites.remove(workKey);
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = _prefs;
    if (prefs == null) return;
    final raw = _favorites.values.map((book) => jsonEncode(book.toJson())).toList();
    await prefs.setStringList(_storageKey, raw);
  }
}
