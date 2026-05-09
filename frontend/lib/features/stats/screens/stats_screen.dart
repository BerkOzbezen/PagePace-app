import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/pp_card.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    final weeklyData = const [
      {'day': 'Pzt', 'minutes': 45},
      {'day': 'Sal', 'minutes': 20},
      {'day': 'Çar', 'minutes': 60},
      {'day': 'Per', 'minutes': 0},
      {'day': 'Cum', 'minutes': 35},
      {'day': 'Cmt', 'minutes': 80},
      {'day': 'Paz', 'minutes': 25},
    ];

    final yearlyStats = const {
      'totalBooks': 7,
      'totalPages': 2340,
      'totalHours': 54,
      'longestStreak': 23,
    };

    const currentStreak = 5;

    final heatmap = const {
      'morning': 8,
      'afternoon': 3,
      'evening': 24,
      'night': 12,
    };

    final streakDays = List<bool>.generate(28, (i) => Random(42 + i).nextBool(), growable: false)
      ..[27] = true;

    final minutes = weeklyData.map((e) => (e['minutes'] as int)).toList(growable: false);
    final maxMinutes = minutes.isEmpty ? 0 : minutes.reduce(max);
    final chartMaxY = max(10, ((maxMinutes / 10).ceil() * 10)).toDouble();

    final emptyDot = isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight;

    return Scaffold(
      appBar: AppBar(title: const Text('İstatistikler')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 108,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _SummaryCard(value: '${yearlyStats['totalBooks']}', label: 'Kitap'),
                  const SizedBox(width: 12),
                  _SummaryCard(value: '2.340', label: 'Sayfa'),
                  const SizedBox(width: 12),
                  _SummaryCard(value: '${yearlyStats['totalHours']}', label: 'Saat'),
                  const SizedBox(width: 12),
                  _SummaryCard(value: '${yearlyStats['longestStreak']}', label: 'Gün Seri'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PPCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🔥 $currentStreak Günlük Seri', style: AppTextStyles.h3.copyWith(color: scheme.onSurface)),
                  const SizedBox(height: 12),
                  _StreakGrid(days: streakDays, activeColor: AppColors.primary, inactiveColor: emptyDot),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PPCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bu Hafta', style: AppTextStyles.h3.copyWith(color: scheme.onSurface)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        maxY: chartMaxY,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: (chartMaxY / 4).clamp(10, 9999),
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: scheme.outline.withValues(alpha: 0.35),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 34,
                              interval: (chartMaxY / 4).clamp(10, 9999),
                              getTitlesWidget: (value, meta) {
                                if (value == 0) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Text(
                                    value.toInt().toString(),
                                    style: AppTextStyles.caption.copyWith(color: scheme.onSurface.withValues(alpha: 0.65)),
                                  ),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx < 0 || idx >= weeklyData.length) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    weeklyData[idx]['day'] as String,
                                    style: AppTextStyles.caption.copyWith(color: scheme.onSurface.withValues(alpha: 0.7)),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barTouchData: BarTouchData(enabled: false),
                        barGroups: List.generate(weeklyData.length, (i) {
                          final v = weeklyData[i]['minutes'] as int;
                          final isZero = v == 0;
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: v.toDouble(),
                                width: 14,
                                borderRadius: BorderRadius.circular(6),
                                color: isZero ? scheme.outline.withValues(alpha: 0.35) : AppColors.primary,
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('Dakika', style: AppTextStyles.caption.copyWith(color: scheme.onSurface.withValues(alpha: 0.6))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PPCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('En Çok Ne Zaman Okuyorsun?', style: AppTextStyles.h3.copyWith(color: scheme.onSurface)),
                  const SizedBox(height: 12),
                  _HeatRow(
                    icon: Icons.wb_sunny_outlined,
                    label: 'Sabah',
                    value: heatmap['morning']!,
                    maxValue: heatmap.values.reduce(max),
                  ),
                  const SizedBox(height: 10),
                  _HeatRow(
                    icon: Icons.lunch_dining_outlined,
                    label: 'Öğlen',
                    value: heatmap['afternoon']!,
                    maxValue: heatmap.values.reduce(max),
                  ),
                  const SizedBox(height: 10),
                  _HeatRow(
                    icon: Icons.nightlight_round,
                    label: 'Akşam',
                    value: heatmap['evening']!,
                    maxValue: heatmap.values.reduce(max),
                  ),
                  const SizedBox(height: 10),
                  _HeatRow(
                    icon: Icons.dark_mode_outlined,
                    label: 'Gece',
                    value: heatmap['night']!,
                    maxValue: heatmap.values.reduce(max),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PPCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('2026 Özeti', style: AppTextStyles.h3.copyWith(color: scheme.onSurface)),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.1,
                    children: [
                      _YearCell(icon: Icons.library_books_outlined, value: '${yearlyStats['totalBooks']}', label: 'Kitap'),
                      _YearCell(icon: Icons.menu_book_outlined, value: '${yearlyStats['totalPages']}', label: 'Sayfa'),
                      _YearCell(icon: Icons.timer_outlined, value: '${yearlyStats['totalHours']}', label: 'Saat'),
                      _YearCell(icon: Icons.local_fire_department_outlined, value: '${yearlyStats['longestStreak']}', label: 'En Uzun Seri'),
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 150,
      child: PPCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppTextStyles.h2.copyWith(color: scheme.onSurface)),
            const SizedBox(height: 6),
            Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _StreakGrid extends StatelessWidget {
  const _StreakGrid({
    required this.days,
    required this.activeColor,
    required this.inactiveColor,
  });

  final List<bool> days;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    // 4 rows x 7 columns
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(28, (i) {
        final active = i < days.length ? days[i] : false;
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: active ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _HeatRow extends StatelessWidget {
  const _HeatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.maxValue,
  });

  final IconData icon;
  final String label;
  final int value;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ratio = maxValue <= 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);
    final isMax = value == maxValue && maxValue > 0;
    final barColor = isMax ? AppColors.primary : AppColors.primary.withValues(alpha: 0.35);

    return Row(
      children: [
        Icon(icon, size: 18, color: scheme.onSurface.withValues(alpha: 0.75)),
        const SizedBox(width: 8),
        SizedBox(
          width: 56,
          child: Text(label, style: AppTextStyles.bodySmall.copyWith(color: scheme.onSurface.withValues(alpha: 0.8))),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(height: 10, color: scheme.outline.withValues(alpha: 0.25)),
                    Container(height: 10, width: constraints.maxWidth * ratio, color: barColor),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('$value', style: AppTextStyles.caption.copyWith(color: scheme.onSurface.withValues(alpha: 0.7))),
      ],
    );
  }
}

class _YearCell extends StatelessWidget {
  const _YearCell({required this.icon, required this.value, required this.label});

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

