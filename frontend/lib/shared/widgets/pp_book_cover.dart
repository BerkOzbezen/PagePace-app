import 'package:flutter/material.dart';

class PPBookCover extends StatelessWidget {
  const PPBookCover({
    super.key,
    required this.coverUrl,
    required this.coverColor,
    this.width = 56,
    this.height = 76,
    this.borderRadius = 10,
    this.iconSize = 28,
  });

  final String coverUrl;
  final Color coverColor;
  final double width;
  final double height;
  final double borderRadius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget placeholder() {
      return Container(
        width: width,
        height: height,
        color: coverColor,
        alignment: Alignment.center,
        child: Icon(
          Icons.menu_book,
          size: iconSize,
          color: scheme.onPrimary.withValues(alpha: 0.9),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: coverUrl.isEmpty
          ? placeholder()
          : Image.network(
              coverUrl,
              width: width,
              height: height,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: width,
                  height: height,
                  color: coverColor,
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (_, __, ___) => placeholder(),
            ),
    );
  }
}
