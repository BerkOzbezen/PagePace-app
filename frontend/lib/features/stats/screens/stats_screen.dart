import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/pp_card.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _api = ApiService();

  List<Map<String, dynamic>> _weekly = [];
  Map<String, dynamic>? _yearly;
  Map<String, dynamic>? _streak;
  Map<String, dynamic>? _heatmap;
  bool _loading = true;

  static const _dayLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      await FirebaseAuth.instance.currentUser?.getIdToken(true);

      final weekly = await _api.getWeeklyStats();
      final yearly = await _api.getYearlyStats();
      final streak = await _api.getStreakStats();
      final heatmap = await _api.getHeatmap();

      if (!mounted) return;
      setState(() {
        _weekly = weekly;
        _yearly = yearly;
        _streak = streak;
        _heatmap = heatmap;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  double _readDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return 0;
  }

  String _formatInt(num value) => value.round().toString();

  String _dayLabel(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return _dayLabels[date.weekday - 1];
    } catch (_) {
      return '';
    }
  }

  List<bool> _buildStreakDays(int currentStreak, String? lastReadDate) {
    final days = List.filled(28, false);
    if (currentStreak <= 0 || lastReadDate == null) return days;

    DateTime streakEnd;
    try {
      streakEnd = DateTime.parse(lastReadDate);
    } catch (_) {
      return days;
    }

    final streakStart = DateTime(streakEnd.year, streakEnd.month, streakEnd.day)
        .subtract(Duration(days: currentStreak - 1));
    final today = DateTime.now();
    final gridStart = DateTime(today.year, today.month, today.day)
        .subtract(const Duration(days: 27));

    for (var i = 0; i < 28; i++) {
      final day = gridStart.add(Duration(days: i));
      final dayOnly = DateTime(day.year, day.month, day.day);
      if (!dayOnly.isBefore(streakStart) && !dayOnly.isAfter(DateTime(
            streakEnd.year,
            streakEnd.month,
            streakEnd.day,
          ))) {
        days[i] = true;
      }
    }
    return days;
  }

  bool get _hasAnyData {
    final weeklyMinutes = _weekly.any((d) => _readDouble(d['total_minutes']) > 0);
    final yearlyPages = _readInt(_yearly?['total_pages']) > 0;
    final currentStreak = _readInt(_streak?['current_streak']) > 0;
    final heatmapTotal = (_readInt(_heatmap?['morning']) +
            _readInt(_heatmap?['afternoon']) +
            _readInt(_heatmap?['evening']) +
            _readInt(_heatmap?['night'])) >
        0;
    return weeklyMinutes || yearlyPages || currentStreak || heatmapTotal;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final emptyDot = isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('İstatistikler')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final totalBooks = _readInt(_yearly?['total_books']);
    final totalPages = _readInt(_yearly?['total_pages']);
    final totalHours = _readDouble(_yearly?['total_hours']).round();
    final currentStreak = _readInt(_streak?['current_streak']);
    final longestStreak = _readInt(_streak?['longest_streak']);
    final lastReadDate = _streak?['last_read_date'] as String?;

    final heatmap = {
      'morning': _readInt(_heatmap?['morning']),
      'afternoon': _readInt(_heatmap?['afternoon']),
      'evening': _readInt(_heatmap?['evening']),
      'night': _readInt(_heatmap?['night']),
    };
    final heatmapMax = heatmap.values.isEmpty ? 0 : heatmap.values.reduce(max);

    final weeklyData = _weekly.isEmpty
        ? List.generate(
            7,
            (i) => {
              'day': _dayLabels[i],
              'minutes': 0,
            },
          )
        : _weekly
            .map(
              (entry) => {
                'day': _dayLabel(entry['date'] as String? ?? ''),
                'minutes': _readDouble(entry['total_minutes']).round(),
              },
            )
            .toList(growable: false);

    final minutes = weeklyData.map((e) => e['minutes'] as int).toList(growable: false);
    final maxMinutes = minutes.isEmpty ? 0 : minutes.reduce(max);
    final chartMaxY = max(10, ((maxMinutes / 10).ceil() * 10)).toDouble();
    final streakDays = _buildStreakDays(currentStreak, lastReadDate);
    final year = DateTime.now().year;

    return Scaffold(
      appBar: AppBar(title: const Text('İstatistikler')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_hasAnyData)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Henüz istatistik yok. Okuma oturumu tamamladığında burada görünecek.',
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                ),
              ),
            SizedBox(
              height: 108,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _SummaryCard(value: _formatInt(totalBooks), label: 'Kitap'),
                  const SizedBox(width: 12),
                  _SummaryCard(value: _formatInt(totalPages), label: 'Sayfa'),
                  const SizedBox(width: 12),
                  _SummaryCard(value: _formatInt(totalHours), label: 'Saat'),
                  const SizedBox(width: 12),
                  _SummaryCard(value: _formatInt(longestStreak), label: 'Gün Seri'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PPCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔥 $currentStreak Günlük Seri',
                    style: AppTextStyles.h3.copyWith(color: scheme.onSurface),
                  ),
                  const SizedBox(height: 12),
                  if (currentStreak == 0)
                    Text(
                      'Henüz seri yok',
                      style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                    )
                  else
                    _StreakGrid(
                      days: streakDays,
                      activeColor: AppColors.primary,
                      inactiveColor: emptyDot,
                    ),
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
                  if (maxMinutes == 0)
                    Text(
                      'Bu hafta henüz okuma yok',
                      style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                    )
                  else
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
                                      style: AppTextStyles.caption.copyWith(
                                        color: scheme.onSurface.withValues(alpha: 0.65),
                                      ),
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
                                  if (idx < 0 || idx >= weeklyData.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      weeklyData[idx]['day'] as String,
                                      style: AppTextStyles.caption.copyWith(
                                        color: scheme.onSurface.withValues(alpha: 0.7),
                                      ),
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
                                  color: isZero
                                      ? scheme.outline.withValues(alpha: 0.35)
                                      : AppColors.primary,
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    'Dakika',
                    style: AppTextStyles.caption.copyWith(color: scheme.onSurface.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PPCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'En Çok Ne Zaman Okuyorsun?',
                    style: AppTextStyles.h3.copyWith(color: scheme.onSurface),
                  ),
                  const SizedBox(height: 12),
                  if (heatmapMax == 0)
                    Text(
                      'Henüz oturum verisi yok',
                      style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                    )
                  else ...[
                    _HeatRow(
                      icon: Icons.wb_sunny_outlined,
                      label: 'Sabah',
                      value: heatmap['morning']!,
                      maxValue: heatmapMax,
                    ),
                    const SizedBox(height: 10),
                    _HeatRow(
                      icon: Icons.lunch_dining_outlined,
                      label: 'Öğlen',
                      value: heatmap['afternoon']!,
                      maxValue: heatmapMax,
                    ),
                    const SizedBox(height: 10),
                    _HeatRow(
                      icon: Icons.nightlight_round,
                      label: 'Akşam',
                      value: heatmap['evening']!,
                      maxValue: heatmapMax,
                    ),
                    const SizedBox(height: 10),
                    _HeatRow(
                      icon: Icons.dark_mode_outlined,
                      label: 'Gece',
                      value: heatmap['night']!,
                      maxValue: heatmapMax,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            PPCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$year Özeti', style: AppTextStyles.h3.copyWith(color: scheme.onSurface)),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.1,
                    children: [
                      _YearCell(
                        icon: Icons.library_books_outlined,
                        value: _formatInt(totalBooks),
                        label: 'Kitap',
                      ),
                      _YearCell(
                        icon: Icons.menu_book_outlined,
                        value: _formatInt(totalPages),
                        label: 'Sayfa',
                      ),
                      _YearCell(
                        icon: Icons.timer_outlined,
                        value: _formatInt(totalHours),
                        label: 'Saat',
                      ),
                      _YearCell(
                        icon: Icons.local_fire_department_outlined,
                        value: _formatInt(longestStreak),
                        label: 'En Uzun Seri',
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
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: scheme.onSurface.withValues(alpha: 0.8)),
          ),
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
