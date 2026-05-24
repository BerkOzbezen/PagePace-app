import 'package:flutter/material.dart';

import '../../../shared/widgets/pp_book_card.dart';

class BookListItem extends StatelessWidget {
  const BookListItem({
    super.key,
    required this.title,
    required this.progress,
    required this.coverColor,
    this.coverUrl = '',
    this.onTap,
  });

  final String title;
  final double progress;
  final Color coverColor;
  final String coverUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PPBookCard(
      title: title,
      progress: progress,
      coverColor: coverColor,
      coverUrl: coverUrl,
      onTap: onTap,
    );
  }
}

