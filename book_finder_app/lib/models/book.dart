/// Modelo que representa um livro obtido pela API pública da Open Library.
///
/// A mesma classe é usada em três contextos:
/// 1) resultado de busca (`Book.fromSearchJson`);
/// 2) item persistido nos favoritos (`Book.toJson` / `Book.fromJson`);
/// 3) exibição na tela de detalhes (campo [description] preenchido sob demanda).
class Book {
  final String workKey; // ex.: "OL82563W" (sem o prefixo "/works/")
  final String title;
  final List<String> authors;
  final int? coverId;
  final int? firstPublishYear;
  final List<String> languages; // códigos ISO, ex.: ["eng", "por"]
  final List<String> publishers;
  final List<String> subjects;
  String? description; // só é preenchido depois da chamada aos detalhes da obra

  Book({
    required this.workKey,
    required this.title,
    required this.authors,
    required this.coverId,
    required this.firstPublishYear,
    required this.languages,
    required this.publishers,
    required this.subjects,
    this.description,
  });

  /// Constrói um [Book] a partir de um item da resposta de
  /// `GET /search.json` da Open Library.
  factory Book.fromSearchJson(Map<String, dynamic> json) {
    final rawKey = (json['key'] as String?) ?? '';
    final rawTitle = json['title'] as String?;
    return Book(
      workKey: rawKey.replaceFirst('/works/', ''),
      title: (rawTitle != null && rawTitle.trim().isNotEmpty) ? rawTitle : 'Título desconhecido',
      authors: _toStringList(json['author_name']),
      coverId: json['cover_i'] as int?,
      firstPublishYear: json['first_publish_year'] as int?,
      languages: _toStringList(json['language']),
      publishers: _toStringList(json['publisher']),
      subjects: _toStringList(json['subject']),
    );
  }

  /// Serializa o livro para salvar localmente (SharedPreferences).
  Map<String, dynamic> toJson() => {
        'workKey': workKey,
        'title': title,
        'authors': authors,
        'coverId': coverId,
        'firstPublishYear': firstPublishYear,
        'languages': languages,
        'publishers': publishers,
        'subjects': subjects,
        'description': description,
      };

  /// Reconstrói um [Book] salvo localmente.
  factory Book.fromJson(Map<String, dynamic> json) => Book(
        workKey: json['workKey'] as String,
        title: json['title'] as String,
        authors: _toStringList(json['authors']),
        coverId: json['coverId'] as int?,
        firstPublishYear: json['firstPublishYear'] as int?,
        languages: _toStringList(json['languages']),
        publishers: _toStringList(json['publishers']),
        subjects: _toStringList(json['subjects']),
        description: json['description'] as String?,
      );

  static List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }

  // ---- Helpers de apresentação usados diretamente pelas telas ----

  String get authorsLabel => authors.isEmpty ? 'Autor desconhecido' : authors.join(', ');

  String? get coverUrlMedium =>
      coverId != null ? 'https://covers.openlibrary.org/b/id/$coverId-M.jpg' : null;

  String? get coverUrlLarge =>
      coverId != null ? 'https://covers.openlibrary.org/b/id/$coverId-L.jpg' : null;

  String get languagesLabel {
    if (languages.isEmpty) return 'Não informado';
    return languages.take(3).map(_languageName).join(', ');
  }

  String get publishersLabel => publishers.isEmpty ? 'Não informado' : publishers.take(2).join(', ');

  /// Resumo curto exibido nos cards da lista de busca/favoritos,
  /// montado a partir do ano e dos assuntos, sem precisar de outra
  /// chamada de API (evita N+1 requisições ao rolar a lista).
  String get shortSummary {
    final parts = <String>[];
    if (firstPublishYear != null) parts.add('${firstPublishYear!}');
    if (subjects.isNotEmpty) parts.add(subjects.take(2).join(', '));
    return parts.isEmpty ? 'Sem informações adicionais.' : parts.join(' · ');
  }

  static const Map<String, String> _languageNames = {
    'eng': 'Inglês',
    'por': 'Português',
    'spa': 'Espanhol',
    'fre': 'Francês',
    'ger': 'Alemão',
    'ita': 'Italiano',
    'jpn': 'Japonês',
    'chi': 'Chinês',
    'rus': 'Russo',
    'ara': 'Árabe',
    'kor': 'Coreano',
    'dut': 'Holandês',
    'swe': 'Sueco',
    'pol': 'Polonês',
  };

  static String _languageName(String code) => _languageNames[code] ?? code.toUpperCase();

  @override
  bool operator ==(Object other) => other is Book && other.workKey == workKey;

  @override
  int get hashCode => workKey.hashCode;
}
