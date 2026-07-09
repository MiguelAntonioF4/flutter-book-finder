import 'package:flutter/material.dart';

import '../models/book.dart';
import '../routes.dart';
import '../services/book_api_service.dart';
import '../services/favorites_service.dart';
import '../widgets/book_card.dart';
import '../widgets/state_views.dart';

enum _ViewState { initial, loading, success, empty, error }

/// Tela inicial: campo de busca + lista de resultados.
/// É a raiz do fluxo de navegação (busca -> detalhes -> favoritos).
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _api = BookApiService();

  _ViewState _state = _ViewState.initial;
  List<Book> _results = const [];
  String _errorMessage = '';

  @override
  void dispose() {
    _controller.dispose();
    _api.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() => _state = _ViewState.loading);

    try {
      final results = await _api.searchBooks(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _state = results.isEmpty ? _ViewState.empty : _ViewState.success;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _state = _ViewState.error;
      });
    }
  }

  void _clearSearch() {
    setState(() {
      _controller.clear();
      _results = const [];
      _state = _ViewState.initial;
    });
  }

  Future<void> _openDetails(Book book) async {
    await Navigator.of(context).pushNamed(AppRoutes.details, arguments: book);
    // Ao voltar da tela de detalhes o favorito pode ter mudado; força um
    // rebuild para atualizar os ícones de coração nos cards da lista.
    if (mounted) setState(() {});
  }

  Future<void> _openFavorites() async {
    await Navigator.of(context).pushNamed(AppRoutes.favorites);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final maxContentWidth = width > 900 ? 700.0 : double.infinity;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Livros'),
        actions: [
          IconButton(
            onPressed: _openFavorites,
            icon: const Icon(Icons.favorite_rounded),
            tooltip: 'Meus favoritos',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  onChanged: (_) => setState(() {}), // atualiza o botão de limpar
                  decoration: InputDecoration(
                    hintText: 'Título, autor ou palavra-chave',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _controller.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: _clearSearch,
                            icon: const Icon(Icons.close),
                            tooltip: 'Limpar busca',
                          ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _state == _ViewState.loading ? null : _search,
                    icon: const Icon(Icons.travel_explore),
                    label: const Text('Buscar'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _ViewState.initial:
        return const EmptyView(
          icon: Icons.auto_stories_rounded,
          message: 'Busque por um título, autor ou tema',
          subtitle: 'Os resultados vêm da Open Library, uma API pública de livros.',
        );
      case _ViewState.loading:
        return const LoadingView(message: 'Buscando livros...');
      case _ViewState.error:
        return ErrorView(message: _errorMessage, onRetry: _search);
      case _ViewState.empty:
        return const EmptyView(
          icon: Icons.search_off_rounded,
          message: 'Nenhum resultado encontrado',
          subtitle: 'Tente outro título, autor ou palavra-chave.',
        );
      case _ViewState.success:
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: _results.length,
          itemBuilder: (context, index) {
            final book = _results[index];
            return BookCard(
              book: book,
              onTap: () => _openDetails(book),
              isFavorite: FavoritesService.instance.isFavorite(book.workKey),
              onFavoriteToggle: () async {
                await FavoritesService.instance.toggleFavorite(book);
                if (mounted) setState(() {});
              },
            );
          },
        );
    }
  }
}
