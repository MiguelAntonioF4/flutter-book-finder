import 'package:flutter/material.dart';

import 'models/book.dart';
import 'routes.dart';
import 'screens/book_details_screen.dart';
import 'services/favorites_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  // Garante que os bindings do Flutter estejam prontos antes de chamadas
  // assíncronas nativas (necessário para o SharedPreferences funcionar
  // antes de `runApp`).
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega os favoritos salvos localmente uma única vez, no início do app.
  await FavoritesService.instance.init();

  runApp(const BookFinderApp());
}

class BookFinderApp extends StatelessWidget {
  const BookFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book Finder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.search,
      routes: AppRoutes.table,
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.details) {
          final book = settings.arguments as Book;
          return MaterialPageRoute(builder: (_) => BookDetailsScreen(book: book));
        }
        return null;
      },
    );
  }
}
