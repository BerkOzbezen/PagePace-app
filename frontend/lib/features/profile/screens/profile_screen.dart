import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  bool _hidden = false;

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
      ),
      body: ListView(
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
                    'BÖ',
                    style: AppTextStyles.h2.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Berk Özbezen', style: AppTextStyles.h2.copyWith(color: scheme.onSurface)),
                const SizedBox(height: 4),
                Text('berk@pagepace.com', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          PPCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatChip(value: '7', label: 'Kitap'),
                _StatChip(value: '54', label: 'Saat'),
                _StatChip(value: '23', label: 'Gün Seri'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PPCard(
            child: Row(
              children: [
                Expanded(
                  child: Text('Profili Gizle', style: AppTextStyles.body.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w600)),
                ),
                Switch(
                  value: _hidden,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _hidden = v),
                ),
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

