import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/book_mapper.dart';
import '../../../shared/widgets/pp_button.dart';
import '../../../shared/widgets/pp_card.dart';

class BookDetailScreen extends StatelessWidget {
  const BookDetailScreen({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final coverColor = Color(coverColorFromId(bookId));

    const title = 'Kitap Detay';
    const totalPages = 0;
    const currentPage = 0;
    const progress = 0.0;
    const percent = 0;

    final sessions = const [
      {'date': '05 May 2026', 'duration': '25 dk', 'range': '160 → 180'},
      {'date': '03 May 2026', 'duration': '40 dk', 'range': '120 → 160'},
      {'date': '01 May 2026', 'duration': '18 dk', 'range': '100 → 120'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitap Detay'),
        automaticallyImplyLeading: true,
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
              child: Icon(Icons.menu_book, size: 64, color: scheme.onPrimary.withValues(alpha: 0.9)),
            ),
          ),
          const SizedBox(height: 14),
          Text(title, style: AppTextStyles.h2.copyWith(color: scheme.onSurface)),
          const SizedBox(height: 4),
          Text('Kitap #$bookId', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          PPCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$currentPage / $totalPages sayfa', style: AppTextStyles.body.copyWith(color: scheme.onSurface)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(value: progress),
                ),
                const SizedBox(height: 8),
                Text('%$percent', style: AppTextStyles.caption.copyWith(color: scheme.onSurface.withValues(alpha: 0.7))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PPCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Saatte ~42 sayfa', style: AppTextStyles.body.copyWith(color: scheme.onSurface)),
                const SizedBox(height: 6),
                Text('~5.5 saatte bitirirsin', style: AppTextStyles.bodySmall.copyWith(color: scheme.onSurface.withValues(alpha: 0.75))),
                const SizedBox(height: 6),
                Text('Tahmini bitiş: 28 Nis 2026', style: AppTextStyles.caption.copyWith(color: scheme.onSurface.withValues(alpha: 0.65))),
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
          Text('Oturum Geçmişi', style: AppTextStyles.h3.copyWith(color: scheme.onSurface)),
          const SizedBox(height: 8),
          ...sessions.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PPCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s['date']!, style: AppTextStyles.body.copyWith(color: scheme.onSurface)),
                          const SizedBox(height: 2),
                          Text(s['range']!, style: AppTextStyles.caption.copyWith(color: scheme.onSurface.withValues(alpha: 0.7))),
                        ],
                      ),
                    ),
                    Text(s['duration']!, style: AppTextStyles.bodySmall.copyWith(color: scheme.onSurface.withValues(alpha: 0.75))),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
