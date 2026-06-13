import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/book_mapper.dart';
import '../../../shared/widgets/pp_card.dart';

class FriendProfileScreen extends StatefulWidget {
  const FriendProfileScreen({super.key, required this.friendId});

  final String friendId;

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  final _api = ApiService();

  String _name = 'Arkadaş';
  bool _loading = true;
  int _weeklyPages = 0;
  int _streak = 0;
  int _totalBooks = 0;
  int _totalPages = 0;
  int _myWeeklyPages = 0;
  int _myStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadFriend();
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  int _sumWeeklyPages(List<Map<String, dynamic>> weekly) {
    var total = 0;
    for (final day in weekly) {
      total += _readInt(day['pages_read']);
    }
    return total;
  }

  String _resolveName(Map<String, dynamic>? friend) {
    if (friend == null) return 'Arkadaş';
    final displayName = friend['display_name'] as String?;
    if (displayName != null && displayName.trim().isNotEmpty) {
      return displayName.trim();
    }
    final name = friend['name'] as String?;
    if (name != null && name.trim().isNotEmpty) {
      return name.trim();
    }
    return 'Arkadaş';
  }

  Future<void> _loadFriend() async {
    try {
      final results = await Future.wait([
        _api.getFriends(),
        _api.getStreakStats(),
        _api.getYearlyStats(),
        _api.getWeeklyStats(),
      ]);
      final friends = results[0] as List<Map<String, dynamic>>;
      final streakStats = results[1] as Map<String, dynamic>;
      final yearlyStats = results[2] as Map<String, dynamic>;
      final weeklyStats = results[3] as List<Map<String, dynamic>>;

      Map<String, dynamic>? match;
      for (final friend in friends) {
        if (friend['uid'] == widget.friendId) {
          match = friend;
          break;
        }
      }

      if (!mounted) return;
      setState(() {
        _name = _resolveName(match);
        if (match != null) {
          _weeklyPages = _readInt(match['weekly_pages'] ?? match['total_pages']);
          _streak = _readInt(match['current_streak']);
          _totalPages = _readInt(match['total_pages']);
          _totalBooks = _readInt(match['total_books']);
        }
        _myStreak = _readInt(streakStats['current_streak']);
        final weeklyFromYearly = (_readInt(yearlyStats['avg_pages_per_day']) * 7).round();
        _myWeeklyPages = _sumWeeklyPages(weeklyStats).clamp(0, 999999);
        if (_myWeeklyPages == 0 && weeklyFromYearly > 0) {
          _myWeeklyPages = weeklyFromYearly;
        }
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.take(1).toString().toUpperCase();
    return '${parts.first.characters.take(1).toString().toUpperCase()}${parts.last.characters.take(1).toString().toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final avatarColor = Color(coverColorFromId(widget.friendId));
    final totalHours = _totalPages <= 0 ? 0 : (_totalPages / 40).round();

    return Scaffold(
      appBar: AppBar(
        title: Text(_name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: avatarColor,
                    child: Text(
                      _initials(_name),
                      style: AppTextStyles.h2.copyWith(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(_name, style: AppTextStyles.h2.copyWith(color: scheme.onSurface)),
                  const SizedBox(height: 6),
                  Text(
                    '$_totalBooks kitap okudu',
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
                        _StatCell(icon: Icons.menu_book_outlined, value: '$_weeklyPages', label: 'Haftalık Sayfa'),
                        _StatCell(icon: Icons.local_fire_department_outlined, value: '$_streak', label: 'Streak'),
                        _StatCell(icon: Icons.library_books_outlined, value: '$_totalBooks', label: 'Toplam Kitap'),
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
                              maxY: max(_myWeeklyPages, _weeklyPages).toDouble() + 20,
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
                                    BarChartRodData(toY: _myWeeklyPages.toDouble(), width: 14, borderRadius: BorderRadius.circular(6), color: AppColors.primary),
                                    BarChartRodData(toY: _weeklyPages.toDouble(), width: 14, borderRadius: BorderRadius.circular(6), color: AppColors.warning),
                                  ],
                                ),
                                BarChartGroupData(
                                  x: 1,
                                  barsSpace: 8,
                                  barRods: [
                                    BarChartRodData(toY: _myStreak.toDouble(), width: 14, borderRadius: BorderRadius.circular(6), color: AppColors.primary),
                                    BarChartRodData(toY: _streak.toDouble(), width: 14, borderRadius: BorderRadius.circular(6), color: AppColors.warning),
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
                              _name.split(' ').first,
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
