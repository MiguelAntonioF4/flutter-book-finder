import 'package:flutter/material.dart';

import '../models/book.dart';

/// Card usado tanto na lista de resultados de busca quanto na lista
/// de favoritos. A capa usa [Hero] para animar a transição até a tela
/// de detalhes, e o ícone de favorito é opcional (a tela decide se
/// mostra a ação de favoritar/remover).
class BookCard extends StatelessWidget {
  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  final Book book;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'cover-${book.workKey}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _Cover(book: book),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.authorsLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      book.shortSummary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ),
              if (onFavoriteToggle != null)
                IconButton(
                  onPressed: onFavoriteToggle,
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? theme.colorScheme.error : theme.colorScheme.outline,
                  ),
                  tooltip: isFavorite ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final url = book.coverUrlMedium;
    const size = Size(64, 96);

    if (url == null) {
      return _placeholder(context, size);
    }

    return Image.network(
      url,
      width: size.width,
      height: size.height,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          width: size.width,
          height: size.height,
          child: const Center(
            child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => _placeholder(context, size),
    );
  }

  Widget _placeholder(BuildContext context, Size size) {
    return Container(
      width: size.width,
      height: size.height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(Icons.menu_book_rounded, color: Theme.of(context).colorScheme.outline),
    );
  }
}
