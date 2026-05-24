import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'pp_book_cover.dart';

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

  static Color colorForProgress(int percent) {
    if (percent <= 30) return AppColors.error;
    if (percent <= 70) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final clamped = progress.clamp(0.0, 1.0);
    final percent = (clamped * 100).round();
    final barColor = colorForProgress(percent);
    final bg = coverColor ?? scheme.surfaceContainerHighest;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outline),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
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
                              child: LinearProgressIndicator(
                                value: clamped,
                                backgroundColor: scheme.outline.withValues(alpha: 0.35),
                                color: barColor,
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '$percent%',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: barColor,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
