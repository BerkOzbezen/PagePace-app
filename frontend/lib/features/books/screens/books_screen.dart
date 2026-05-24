import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/book_mapper.dart';
import '../../../shared/widgets/pp_button.dart';
import '../widgets/book_list_item.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  final _api = ApiService();

  bool _loading = true;
  bool _loadFailed = false;
  List<Map<String, Object?>> _books = [];

  @override
  void initState() {
    super.initState();
    debugPrint('Books screen loaded');
    debugPrint('Current user: ${FirebaseAuth.instance.currentUser?.email}');
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });

    await FirebaseAuth.instance.currentUser?.getIdToken(true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('Books load aborted: no authenticated user');
        if (!mounted) return;
        setState(() {
          _books = [];
          _loading = false;
          _loadFailed = true;
        });
        return;
      }

      final raw = await _api.getBooks();
      final books = raw.map(bookFromApi).toList(growable: false);
      if (!mounted) return;
      setState(() {
        _books = books;
        _loading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Failed to load books: $e');
      debugPrint('$stackTrace');
      if (!mounted) return;
      setState(() {
        _books = [];
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  List<Map<String, Object?>> _filtered(String status) => _books
      .where((b) => b['status'] == status)
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        scrolledUnderElevation: 4,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.14),
                scheme.surface,
              ],
            ),
          ),
        ),
        title: const Text('Kitaplığım'),
        actions: [
          IconButton(
            tooltip: 'Profil',
            onPressed: () => context.go('/profile'),
            icon: const CircleAvatar(
              radius: 16,
              child: Icon(Icons.person, size: 18),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadFailed
              ? Center(
                  child: Text(
                    'Yüklenemedi',
                    style: AppTextStyles.h3.copyWith(color: scheme.onSurface),
                  ),
                )
              : _books.isEmpty
                  ? const _EmptyLibraryView()
                  : DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      TabBar(
                        dividerColor: scheme.outline.withValues(alpha: 0.7),
                        labelStyle: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                        tabs: const [
                          Tab(text: 'Okuyor'),
                          Tab(text: 'Tamamlandı'),
                          Tab(text: 'Liste'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _BooksTab(
                              books: _filtered('reading'),
                              emptyLabel: 'Henüz kitap yok',
                            ),
                            _BooksTab(
                              books: _filtered('completed'),
                              emptyLabel: 'Henüz kitap yok',
                            ),
                            _BooksTab(
                              books: _filtered('wishlist'),
                              emptyLabel: 'Henüz kitap yok',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/books/add');
          if (mounted) _loadBooks();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _BooksTab extends StatelessWidget {
  const _BooksTab({required this.books, required this.emptyLabel});

  final List<Map<String, Object?>> books;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (books.isEmpty) {
      return Center(
        child: Text(
          emptyLabel,
          style: AppTextStyles.body.copyWith(color: scheme.onSurface.withValues(alpha: 0.7)),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: books.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final b = books[i];
        final id = (b['id'] as String?) ?? '';
        final title = (b['title'] as String?) ?? '';
        final total = (b['totalPages'] as int?) ?? 0;
        final current = (b['currentPage'] as int?) ?? 0;
        final progress = total <= 0 ? 0.0 : (current / total).clamp(0.0, 1.0);
        final cover = Color(((b['coverColor'] as int?) ?? 0xFF6C63FF));
        final coverUrl = (b['coverUrl'] as String?) ?? '';

        return BookListItem(
          title: title,
          progress: progress,
          coverColor: cover,
          coverUrl: coverUrl,
          onTap: () => context.go('/books/$id'),
        );
      },
    );
  }
}

class _EmptyLibraryView extends StatelessWidget {
  const _EmptyLibraryView();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.menu_book, size: 80, color: AppColors.primary),
              const SizedBox(height: 20),
              Text(
                'Henüz kitap eklemediniz',
                style: AppTextStyles.h3.copyWith(color: scheme.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              PPButton(
                label: 'İlk kitabınızı ekleyin',
                fullWidth: true,
                onPressed: () => context.go('/books/add'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
