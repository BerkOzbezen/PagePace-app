import 'package:flutter/material.dart';

import 'pp_book_cover.dart';
import 'pp_card.dart';

class PPBookCard extends StatelessWidget {
  const PPBookCard({
    super.key,
    required this.title,
    required this.progress,
    this.coverColor,
    this.coverUrl = '',
    this.onTap,
  });

  final String title;
  final double progress;
  final Color? coverColor;
  final String coverUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final clamped = progress.clamp(0.0, 1.0);
    final percent = (clamped * 100).round();
    final bg = coverColor ?? scheme.surfaceContainerHighest;

    return PPCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          PPBookCover(
            coverUrl: coverUrl,
            coverColor: bg,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(value: clamped),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$percent%',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
