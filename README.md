# Book Finder — App de Busca e Organização de Livros

Aplicativo em Flutter para pesquisar livros por título, autor ou palavra-chave usando a
API pública da [Open Library](https://openlibrary.org/dev/docs/api/search), visualizar
detalhes de cada obra e salvar favoritos localmente no dispositivo.

## Nome do curso

[Analise Desenvolvimento de Sistemas]

## Nome da unidade curricular

[Desenvolvimento para Dispositivos Móveis]

## Alunos

- [Luiz F](https://github.com/XT07)
- [Miguel A](https://github.com/MiguelAntonioF4)
- [Natanael B](https://github.com/NatanaelBeloqui)


---

## Explicação técnica

### Stack

- **Flutter / Dart** — SDK `>=3.0.0 <4.0.0`, Material Design 3.
- **http** — requisições REST para a Open Library (`search.json` e `works/{id}.json`).
- **shared_preferences** — persistência local dos favoritos (dados sobrevivem ao fechar o app).

### Arquitetura de pastas

```
lib/
├── main.dart                     # bootstrap do app, tema e rotas
├── routes.dart                   # nomes de rota centralizados
├── models/
│   └── book.dart                 # modelo Book + parsing da API + serialização local
├── services/
│   ├── book_api_service.dart     # chamadas HTTP e tratamento de erros
│   └── favorites_service.dart    # persistência dos favoritos (singleton)
├── screens/
│   ├── search_screen.dart        # busca + lista de resultados
│   ├── book_details_screen.dart  # detalhes do livro + favoritar
│   └── favorites_screen.dart     # lista de favoritos + remover
└── widgets/
    ├── book_card.dart            # card reutilizável (busca e favoritos)
    └── state_views.dart          # loading / vazio / erro, reutilizados nas telas
```

### Decisões de design

- **Gerenciamento de estado**: `StatefulWidget` + `setState`, sem bibliotecas externas de
  state management. O `FavoritesService` é um singleton com cache em memória carregado uma
  única vez em `main()`; por isso as telas conseguem ler `isFavorite()` de forma síncrona e
  só chamam `setState` depois de favoritar/remover.
- **Navegação**: rotas nomeadas (`Navigator 1.0`) — `/` (busca), `/details` (recebe um
  `Book` via `arguments`) e `/favorites`. `onGenerateRoute` resolve a rota de detalhes por
  precisar de argumento.
- **Tratamento de erros de rede**: `BookApiService` captura `SocketException` (sem internet),
  `TimeoutException` (demora excessiva) e status HTTP diferente de 200, convertendo tudo em
  mensagens legíveis exibidas na tela (`ErrorView`, com botão "Tentar novamente").
  Resultado vazio é tratado separadamente de erro.
- **Performance na lista**: `ListView.builder` (lazy loading) — os itens só são construídos
  conforme aparecem na tela.
- **Resumo sem custo extra de API**: o "resumo curto" do card é montado a partir do ano e dos
  assuntos já presentes na resposta de busca, evitando uma requisição por item da lista. A
  sinopse completa só é buscada quando o usuário abre a tela de detalhes.
- **Componente visual elaborado**: `Hero` na capa do livro (transição animada da lista para
  os detalhes) + cards com sombra/raio + chips de metadados (ano, idioma, editora).
- **Responsividade**: a lista de resultados é limitada a uma largura máxima central em telas
  largas (`MediaQuery` + `ConstrainedBox`), evitando cards esticados em tablets.

---

## Como instalar e rodar o app

1. Instale o [Flutter SDK](https://docs.flutter.dev/get-started/install).
2. Crie o projeto base (gera as pastas `android/`, `ios/`, etc. que não vêm neste pacote de
   código-fonte):
   ```bash
   flutter create book_finder_app
   ```
3. Substitua o conteúdo gerado por este projeto: copie `lib/`, `pubspec.yaml`,
   `analysis_options.yaml` e `.gitignore` para dentro da pasta criada no passo anterior,
   sobrescrevendo os arquivos padrão do template.
4. Instale as dependências:
   ```bash
   flutter pub get
   ```
5. Rode o app (emulador Android ou dispositivo físico conectado):
   ```bash
   flutter run
   ```

> **Permissão de internet (Android)**: confirme que
> `android/app/src/main/AndroidManifest.xml` contém
> `<uses-permission android:name="android.permission.INTERNET"/>` — o `flutter create`
> mais recente já inclui isso por padrão, mas vale conferir, já que o app depende de
> requisições HTTP para funcionar.

---

## Funcionalidades principais

- Busca de livros por título, autor ou palavra-chave (Open Library).
- Lista de resultados com capa, título, autor e resumo curto.
- Estados de carregamento, erro (com "tentar novamente") e "nenhum resultado".
- Botão para limpar a busca e reiniciar a consulta.
- Tela de detalhes com capa ampliada, ano, idioma(s), editora(s) e sinopse.
- Favoritar/desfavoritar a partir da busca ou da tela de detalhes.
- Tela de favoritos com opção de remover (com "desfazer" via SnackBar).
- Favoritos persistidos localmente (`shared_preferences`) — sobrevivem ao fechar o app.
- Navegação: busca → detalhes → favoritos, com Navigator 1.0 e rotas nomeadas.
- Interface responsiva (Material Design 3) para telas pequenas e médias.

---

## Estratégia de colaboração e Pull Requests

Como o app já está estruturado em módulos independentes, a divisão de commits/PRs entre os
4 integrantes pode seguir os próprios arquivos do projeto:

- **Miguel A** — estrutura inicial, `main.dart`, `routes.dart`, tema (`theme/app_theme.dart`)
  e navegação entre telas.
- **Luiz F** — integração com a API (`services/book_api_service.dart`, `models/book.dart`)
  e tratamento de erros de rede.
- **Natanael B** — armazenamento local e favoritos (`services/favorites_service.dart`,
  `screens/favorites_screen.dart`).
- **Natanael B** — UI (`widgets/book_card.dart`, `widgets/state_views.dart`,
  `screens/search_screen.dart`, `screens/book_details_screen.dart`) e finalização do README.
  
