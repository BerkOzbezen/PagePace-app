import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/book_mapper.dart';
import '../../../shared/widgets/pp_card.dart';

class FriendProfileScreen extends StatelessWidget {
  const FriendProfileScreen({super.key, required this.friendId});

  final String friendId;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.take(1).toString().toUpperCase();
    return '${parts.first.characters.take(1).toString().toUpperCase()}${parts.last.characters.take(1).toString().toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const name = 'Arkadaş';
    const weeklyPages = 0;
    const streak = 0;
    const totalBooks = 0;
    const myWeeklyPages = 0;
    const myStreak = 0;
    final avatarColor = Color(coverColorFromId(friendId));
    final totalHours = max(10, (weeklyPages / 12).round() + 18);

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: avatarColor,
              child: Text(
                _initials(name),
                style: AppTextStyles.h2.copyWith(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(name, style: AppTextStyles.h2.copyWith(color: scheme.onSurface)),
            const SizedBox(height: 6),
            Text(
              '$totalBooks kitap okudu',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            PPCard(
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.2,
                children: [
                  _StatCell(icon: Icons.menu_book_outlined, value: '$weeklyPages', label: 'Haftalık Sayfa'),
                  _StatCell(icon: Icons.local_fire_department_outlined, value: '$streak', label: 'Streak'),
                  _StatCell(icon: Icons.library_books_outlined, value: '$totalBooks', label: 'Toplam Kitap'),
                  _StatCell(icon: Icons.timer_outlined, value: '$totalHours', label: 'Toplam Saat'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PPCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sen vs Arkadaş', style: AppTextStyles.h3.copyWith(color: scheme.onSurface)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 190,
                    child: BarChart(
                      BarChartData(
                        maxY: max(myWeeklyPages, weeklyPages).toDouble() + 20,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: scheme.outline.withValues(alpha: 0.35),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                final label = switch (idx) { 0 => 'Sayfa', 1 => 'Streak', _ => '' };
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    label,
                                    style: AppTextStyles.caption.copyWith(color: scheme.onSurface.withValues(alpha: 0.75)),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barTouchData: BarTouchData(enabled: false),
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                            barsSpace: 8,
                            barRods: [
                              BarChartRodData(toY: myWeeklyPages.toDouble(), width: 14, borderRadius: BorderRadius.circular(6), color: AppColors.primary),
                              BarChartRodData(toY: weeklyPages.toDouble(), width: 14, borderRadius: BorderRadius.circular(6), color: AppColors.warning),
                            ],
                          ),
                          BarChartGroupData(
                            x: 1,
                            barsSpace: 8,
                            barRods: [
                              BarChartRodData(toY: myStreak.toDouble(), width: 14, borderRadius: BorderRadius.circular(6), color: AppColors.primary),
                              BarChartRodData(toY: streak.toDouble(), width: 14, borderRadius: BorderRadius.circular(6), color: AppColors.warning),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _LegendDot(color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text('Sen', style: AppTextStyles.caption.copyWith(color: scheme.onSurface.withValues(alpha: 0.75))),
                      const SizedBox(width: 14),
                      _LegendDot(color: AppColors.warning),
                      const SizedBox(width: 6),
                      Text(
                        name.split(' ').first,
                        style: AppTextStyles.caption.copyWith(color: scheme.onSurface.withValues(alpha: 0.75)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.onSurface.withValues(alpha: 0.75)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: AppTextStyles.h3.copyWith(color: scheme.onSurface)),
                const SizedBox(height: 2),
                Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
