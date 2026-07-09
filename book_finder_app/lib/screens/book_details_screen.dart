import 'package:flutter/material.dart';

import '../models/book.dart';
import '../services/book_api_service.dart';
import '../services/favorites_service.dart';

/// Tela de detalhes de um livro. Recebe o [Book] já carregado pela busca
/// (evitando uma nova requisição para os dados básicos) e busca só a
/// sinopse completa sob demanda.
class BookDetailsScreen extends StatefulWidget {
  const BookDetailsScreen({super.key, required this.book});

  final Book book;

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  final _api = BookApiService();

  late bool _isFavorite;
  bool _loadingDescription = true;
  String? _description;

  @override
  void initState() {
    super.initState();
    _isFavorite = FavoritesService.instance.isFavorite(widget.book.workKey);
    _description = widget.book.description;
    if (_description == null) {
      _loadDescription();
    } else {
      _loadingDescription = false;
    }
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _loadDescription() async {
    final description = await _api.fetchDescription(widget.book.workKey);
    widget.book.description = description;
    if (!mounted) return;
    setState(() {
      _description = description;
      _loadingDescription = false;
    });
  }

  Future<void> _toggleFavorite() async {
    final nowFavorite = await FavoritesService.instance.toggleFavorite(widget.book);
    if (!mounted) return;
    setState(() => _isFavorite = nowFavorite);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(nowFavorite ? 'Adicionado aos favoritos' : 'Removido dos favoritos'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do livro')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Hero(
                tag: 'cover-${book.workKey}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: book.coverUrlLarge != null
                      ? Image.network(
                          book.coverUrlLarge!,
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _coverPlaceholder(theme),
                        )
                      : _coverPlaceholder(theme),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(book.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(book.authorsLabel, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(icon: Icons.calendar_today, label: book.firstPublishYear?.toString() ?? 'Ano desconhecido'),
                _InfoChip(icon: Icons.language, label: book.languagesLabel),
                _InfoChip(icon: Icons.business, label: book.publishersLabel),
              ],
            ),
            const SizedBox(height: 24),
            Text('Sinopse', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (_loadingDescription)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              Text(
                _description?.trim().isNotEmpty == true
                    ? _description!.trim()
                    : 'Sinopse não disponível para este livro.',
                style: theme.textTheme.bodyMedium,
              ),
            const SizedBox(height: 90), // espaço para o FAB não cobrir o texto
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleFavorite,
        icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
        label: Text(_isFavorite ? 'Remover dos favoritos' : 'Adicionar aos favoritos'),
      ),
    );
  }

  Widget _coverPlaceholder(ThemeData theme) {
    return Container(
      height: 220,
      width: 150,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(Icons.menu_book_rounded, size: 48, color: theme.colorScheme.outline),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}
