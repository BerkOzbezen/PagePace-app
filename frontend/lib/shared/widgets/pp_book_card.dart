import 'package:flutter/material.dart';

import 'pp_card.dart';

class PPBookCard extends StatelessWidget {
  const PPBookCard({
    super.key,
    required this.title,
    required this.progress, // 0..1
    this.coverColor,
    this.coverImage,
    this.onTap,
  });

  final String title;
  final double progress;
  final Color? coverColor;
  final ImageProvider? coverImage;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final clamped = progress.clamp(0.0, 1.0);
    final percent = (clamped * 100).round();

    return PPCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _Cover(image: coverImage, color: coverColor),
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

class _Cover extends StatelessWidget {
  const _Cover({this.image, this.color});

  final ImageProvider? image;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = color ?? scheme.surfaceContainerHighest;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 56,
        height: 76,
        color: bg,
        child: image == null
            ? Icon(Icons.menu_book, color: scheme.onSurface.withValues(alpha: 0.55))
            : Image(image: image!, fit: BoxFit.cover),
      ),
    );
  }
}

