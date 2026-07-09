import 'package:flutter/material.dart';

import 'screens/favorites_screen.dart';
import 'screens/search_screen.dart';

/// Nomes de rota centralizados para evitar strings soltas espalhadas
/// pelo app (Navigator 1.0 com rotas nomeadas, conforme visto em aula).
class AppRoutes {
  AppRoutes._();

  static const String search = '/';
  static const String details = '/details';
  static const String favorites = '/favorites';

  /// Rotas simples, sem argumentos, registradas direto no MaterialApp.
  static Map<String, WidgetBuilder> get table => {
        search: (_) => const SearchScreen(),
        favorites: (_) => const FavoritesScreen(),
      };

  // A rota "details" precisa receber um Book como argumento, então ela é
  // resolvida em `onGenerateRoute`, dentro de main.dart.
}
