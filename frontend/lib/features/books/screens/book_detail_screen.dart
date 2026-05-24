import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/book_mapper.dart';
import '../../../shared/widgets/pp_button.dart';
import '../../../shared/widgets/pp_card.dart';

class BookDetailScreen extends StatefulWidget {
  const BookDetailScreen({super.key, required this.bookId});
  final String bookId;

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final _api = ApiService();
  Map<String, Object?>? _book;
  Map<String, dynamic>? _pace;
  List<Map<String, dynamic>> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    await FirebaseAuth.instance.currentUser?.getIdToken(true);

    Map<String, Object?>? book;
    Map<String, dynamic>? pace;
    var sessions = <Map<String, dynamic>>[];

    try {
      final raw = await _api.getBook(widget.bookId);
      book = bookFromApi(raw);
    } catch (_) {}

    try {
      pace = await _api.getBookPace(widget.bookId);
    } catch (_) {}

    try {
      sessions = await _api.getSessions(widget.bookId);
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _book = book;
      _pace = pace;
      _sessions = sessions;
      _loading = false;
    });
  }

  String _formatPaceNum(dynamic value, {int fractionDigits = 0}) {
    if (value is! num) return '-';
    if (fractionDigits == 0) return value.round().toString();
    return value.toStringAsFixed(fractionDigits);
  }

  String _formatSessionDate(dynamic startedAt) {
    if (startedAt == null) return '';
    final text = startedAt.toString();
    return text.length >= 10 ? text.substring(0, 10) : text;
  }

  int _readSessionInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final coverColor = Color(coverColorFromId(widget.bookId));
    final title = (_book?['title'] as String?)?.trim().isNotEmpty == true
        ? _book!['title'] as String
        : 'Kitap';

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Kitap'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final totalPages = (_book?['totalPages'] as int?) ?? 0;
    final currentPage = (_book?['currentPage'] as int?) ?? 0;
    final progress = totalPages > 0 ? currentPage / totalPages : 0.0;
    final percent = (progress * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 200,
              color: coverColor,
              alignment: Alignment.center,
              child: Icon(
                Icons.menu_book,
                size: 64,
                color: scheme.onPrimary.withValues(alpha: 0.9),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: AppTextStyles.h2.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: 16),
          PPCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$currentPage / $totalPages sayfa',
                  style: AppTextStyles.body.copyWith(color: scheme.onSurface),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(value: progress),
                ),
                const SizedBox(height: 8),
                Text(
                  '%$percent',
                  style: AppTextStyles.caption.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PPCard(
            child: _pace == null
                ? Text(
                    'Hız hesabı için en az 2 oturum tamamla',
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saatte ~${_formatPaceNum(_pace!['pages_per_hour'])} sayfa',
                        style: AppTextStyles.body.copyWith(color: scheme.onSurface),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '~${_formatPaceNum(_pace!['estimated_hours'], fractionDigits: 1)} saatte bitirirsin',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (_pace!['estimated_finish_date'] != null)
                        Text(
                          'Tahmini bitiş: ${_pace!['estimated_finish_date']}',
                          style: AppTextStyles.caption.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          PPButton(
            label: 'Okumaya Başla',
            fullWidth: true,
            onPressed: () => context.go('/timer'),
          ),
          const SizedBox(height: 18),
          Text(
            'Oturum Geçmişi',
            style: AppTextStyles.h3.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: 8),
          if (_sessions.isEmpty)
            Text(
              'Henüz oturum yok',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            )
          else
            ..._sessions.map((s) {
              final startPage = _readSessionInt(s['start_page']);
              final endPage = _readSessionInt(s['end_page']);
              final duration = _readSessionInt(s['duration_seconds']);
              final minutes = (duration / 60).round();
              final date = _formatSessionDate(s['started_at']);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PPCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              date,
                              style: AppTextStyles.body.copyWith(color: scheme.onSurface),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$startPage → $endPage',
                              style: AppTextStyles.caption.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '$minutes dk',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
