import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/book_mapper.dart';
import '../../../core/exceptions/api_exceptions.dart';
import '../../../shared/widgets/pp_button.dart';
import '../../../shared/widgets/pp_card.dart';
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
  int _currentStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadBooks();
    _loadStreak();
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

  Future<void> _loadStreak() async {
    try {
      final streak = await _api.getStreakStats();
      final current = streak['current_streak'];
      if (!mounted) return;
      setState(() {
        _currentStreak = (current is int) ? current : (current is num ? current.toInt() : 0);
      });
    } catch (_) {}
  }

  List<Map<String, Object?>> _filtered(String status) => _books
      .where((b) => b['status'] == status)
      .toList(growable: false);

  Future<void> _showAiRecommendations() async {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );

    try {
      final recommendations = await _api.getAiRecommendations();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (!mounted) return;
      final scheme = Theme.of(context).colorScheme;

      await showDialog<void>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✨ AI Kitap Önerileri',
                  style: AppTextStyles.h3.copyWith(color: scheme.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  'Okuma geçmişine göre seçildi',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: recommendations.isEmpty
                  ? Text(
                      'Öneri bulunamadı. Önce kitaplığına kitap ekle.',
                      style: AppTextStyles.body.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < recommendations.length; i++) ...[
                          if (i > 0) const Divider(height: 24),
                          _AiRecommendationCard(item: recommendations[i]),
                        ],
                      ],
                    ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => ctx.pop(),
                child: const Text('Kapat'),
              ),
            ],
          );
        },
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI önerileri alınamadı')),
      );
    }
  }

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
                  : Column(
                      children: [
                        if (_currentStreak > 0)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            color: AppColors.primary.withValues(alpha: 0.15),
                            child: Text(
                              '🔥 $_currentStreak günlük seri devam ediyor!',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        Expanded(
                          child: DefaultTabController(
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
                                        emptyLabel: 'Şu an okuduğun kitap yok',
                                        showAiCard: true,
                                        onAiTap: _showAiRecommendations,
                                      ),
                                      _BooksTab(
                                        books: _filtered('completed'),
                                        emptyLabel: 'Henüz tamamlanan kitap yok',
                                      ),
                                      _BooksTab(
                                        books: _filtered('wishlist'),
                                        emptyLabel: 'İstek listesi boş',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
  const _BooksTab({
    required this.books,
    required this.emptyLabel,
    this.showAiCard = false,
    this.onAiTap,
  });

  final List<Map<String, Object?>> books;
  final String emptyLabel;
  final bool showAiCard;
  final VoidCallback? onAiTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (!showAiCard && books.isEmpty) {
      return Center(
        child: Text(
          emptyLabel,
          style: AppTextStyles.body.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      );
    }

    final itemCount = books.length +
        (showAiCard ? 1 : 0) +
        (books.isEmpty ? 1 : 0);

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        if (showAiCard && i == 0) {
          return _AiPromptCard(onTap: onAiTap!);
        }

        if (books.isEmpty) {
          return Text(
            emptyLabel,
            style: AppTextStyles.body.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          );
        }

        final bookIndex = showAiCard ? i - 1 : i;
        final b = books[bookIndex];
        final id = (b['id'] as String?) ?? '';
        final title = (b['title'] as String?) ?? '';
        final total = (b['totalPages'] as int?) ?? 0;
        final current = (b['currentPage'] as int?) ?? 0;
        final progress = total <= 0 ? 0.0 : (current / total).clamp(0.0, 1.0);
        final cover = Color(((b['coverColor'] as int?) ?? 0xFF6C63FF));
        final coverUrl = (b['coverUrl'] as String?) ?? '';
        final status = (b['status'] as String?) ?? 'reading';

        return BookListItem(
          title: title,
          progress: progress,
          coverColor: cover,
          coverUrl: coverUrl,
          status: status,
          onTap: () => context.go('/books/$id'),
        );
      },
    );
  }
}

class _AiPromptCard extends StatelessWidget {
  const _AiPromptCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Theme(
      data: Theme.of(context).copyWith(
        cardTheme: Theme.of(context).cardTheme.copyWith(
              color: AppColors.primary.withValues(alpha: 0.08),
            ),
      ),
      child: PPCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.primary, size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✨ AI Kitap Önerisi',
                    style: AppTextStyles.h3.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Okuma geçmişine göre kişisel öneriler',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: scheme.onSurface.withValues(alpha: 0.45),
            ),
          ],
        ),
      ),
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
                'Okuma yolculuğuna başla!',
                style: AppTextStyles.h3.copyWith(color: scheme.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'İlk kitabını ekle ve okuma serini başlat',
                style: AppTextStyles.body.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              PPButton(
                label: 'İlk kitabını ekle',
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

class _AiRecommendationCard extends StatelessWidget {
  const _AiRecommendationCard({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = item['title'] as String? ?? '';
    final author = item['author'] as String? ?? '';
    final reason = item['reason'] as String? ?? '';

    return PPCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.h3.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (author.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              author,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              reason,
              style: AppTextStyles.body.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.85),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
