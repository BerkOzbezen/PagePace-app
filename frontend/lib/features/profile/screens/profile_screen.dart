import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/pp_button.dart';
import '../../../shared/widgets/pp_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = ApiService();

  bool _loading = true;
  String _displayName = '';
  String _email = '';
  String _initials = '?';
  int _totalBooks = 0;
  int _totalHours = 0;
  int _currentStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName;
    final email = user?.email ?? '';

    var totalBooks = 0;
    var totalHours = 0;
    var currentStreak = 0;

    try {
      final yearly = await _api.getYearlyStats();
      totalBooks = _readInt(yearly['total_books']);
      totalHours = _readDouble(yearly['total_hours']).round();
    } catch (_) {}

    try {
      final streak = await _api.getStreakStats();
      currentStreak = _readInt(streak['current_streak']);
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _displayName = displayName ?? '';
      _email = email;
      _initials = _initialsFrom(displayName, email);
      _totalBooks = totalBooks;
      _totalHours = totalHours;
      _currentStreak = currentStreak;
      _loading = false;
    });
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

  String _initialsFrom(String? displayName, String email) {
    if (displayName != null && displayName.trim().isNotEmpty) {
      final parts = displayName.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
      }
      return parts.first[0].toUpperCase();
    }
    if (email.isNotEmpty) return email[0].toUpperCase();
    return '?';
  }

  String get _nameLabel {
    if (_displayName.trim().isNotEmpty) return _displayName;
    if (_email.isNotEmpty) return _email.split('@').first;
    return 'Kullanıcı';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/books'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _initials,
                          style: AppTextStyles.h2.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _nameLabel,
                        style: AppTextStyles.h2.copyWith(color: scheme.onSurface),
                      ),
                      const SizedBox(height: 4),
                      if (_email.isNotEmpty)
                        Text(
                          _email,
                          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                PPCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatChip(value: '$_totalBooks', label: 'Kitap'),
                      _StatChip(value: '$_totalHours', label: 'Saat'),
                      _StatChip(value: '$_currentStreak', label: 'Gün Seri'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                PPButton(
                  label: 'Çıkış Yap',
                  variant: PPButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
            ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: AppTextStyles.h3.copyWith(color: scheme.onSurface)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}
