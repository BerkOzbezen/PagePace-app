import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/pp_button.dart';
import '../../../shared/widgets/pp_card.dart';
import '../widgets/book_list_item.dart';

final mockBooks = [
  {
    'id': '1',
    'title': 'Dune',
    'author': 'Frank Herbert',
    'totalPages': 412,
    'currentPage': 180,
    'status': 'reading',
    'coverColor': 0xFF6C63FF,
  },
  {
    'id': '2',
    'title': 'Atomik Alışkanlıklar',
    'author': 'James Clear',
    'totalPages': 320,
    'currentPage': 320,
    'status': 'completed',
    'coverColor': 0xFF22C55E,
  },
  {
    'id': '3',
    'title': 'Sapiens',
    'author': 'Yuval Noah Harari',
    'totalPages': 510,
    'currentPage': 0,
    'status': 'wishlist',
    'coverColor': 0xFFF59E0B,
  },
  {
    'id': '4',
    'title': 'Savaş ve Barış',
    'author': 'Lev Tolstoy',
    'totalPages': 1392,
    'currentPage': 240,
    'status': 'reading',
    'coverColor': 0xFFEF4444,
  },
];

class BooksScreen extends StatelessWidget {
  const BooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    List<Map<String, Object?>> filtered(String status) => mockBooks
        .cast<Map<String, Object?>>()
        .where((b) => b['status'] == status)
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
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
      body: DefaultTabController(
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
                    books: filtered('reading'),
                    emptyLabel: 'Henüz kitap yok',
                  ),
                  _BooksTab(
                    books: filtered('completed'),
                    emptyLabel: 'Henüz kitap yok',
                  ),
                  _BooksTab(
                    books: filtered('wishlist'),
                    emptyLabel: 'Henüz kitap yok',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/books/add'),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: PPCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emptyLabel, style: AppTextStyles.h3.copyWith(color: scheme.onSurface)),
                  const SizedBox(height: 8),
                  Text(
                    'Kütüphaneni oluşturmaya başla.',
                    style: AppTextStyles.bodySmall.copyWith(color: scheme.onSurface.withValues(alpha: 0.7)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  PPButton(
                    label: 'Kitap ekle',
                    fullWidth: true,
                    onPressed: () => context.go('/books/add'),
                  ),
                ],
              ),
            ),
          ),
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

        return BookListItem(
          title: title,
          progress: progress,
          coverColor: cover,
          onTap: () => context.go('/books/$id'),
        );
      },
    );
  }
}

