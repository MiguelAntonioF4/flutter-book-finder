import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/book.dart';

/// Exceção lançada quando a busca ou a consulta de detalhes falha.
/// A [message] já vem pronta em português para ser exibida direto na tela.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

/// Camada de acesso à API pública da Open Library (https://openlibrary.org).
///
/// Isolar as chamadas HTTP aqui (em vez de fazer isso direto nas telas)
/// permite trocar de API no futuro mexendo em um único arquivo.
class BookApiService {
  BookApiService({http.Client? client}) : _client = client ?? http.Client();

  static const _baseUrl = 'https://openlibrary.org';
  final http.Client _client;

  /// Busca livros por título, autor ou palavra-chave.
  /// Retorna uma lista vazia se [query] estiver em branco ou se a
  /// API não encontrar nenhum resultado.
  Future<List<Book>> searchBooks(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final uri = Uri.parse('$_baseUrl/search.json').replace(queryParameters: {
      'q': trimmed,
      'limit': '24',
      'fields': 'key,title,author_name,cover_i,first_publish_year,language,publisher,subject',
    });

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        throw ApiException('O servidor retornou um erro (código ${response.statusCode}). Tente novamente.');
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw ApiException('Resposta inesperada do servidor.');
      }

      final docs = decoded['docs'];
      if (docs is! List) return [];

      return docs.whereType<Map<String, dynamic>>().map(Book.fromSearchJson).toList();
    } on SocketException {
      throw ApiException('Sem conexão com a internet. Verifique sua rede e tente novamente.');
    } on TimeoutException {
      throw ApiException('A busca demorou demais para responder. Tente novamente.');
    } on FormatException {
      throw ApiException('Não foi possível interpretar a resposta do servidor.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Não foi possível concluir a busca. Detalhe: $e');
    }
  }

  /// Busca a sinopse completa de uma obra (usada na tela de detalhes).
  /// Retorna `null` em caso de falha — a descrição é um complemento e
  /// não deve travar a exibição dos dados já conhecidos do livro.
  Future<String?> fetchDescription(String workKey) async {
    try {
      final uri = Uri.parse('$_baseUrl/works/$workKey.json');
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) return null;

      final desc = decoded['description'];
      if (desc is String) return desc;
      if (desc is Map && desc['value'] is String) return desc['value'] as String;
      return null;
    } catch (_) {
      return null;
    }
  }

  void dispose() => _client.close();
}
