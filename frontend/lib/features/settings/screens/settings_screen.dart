import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/theme_provider.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/pp_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/profile'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PPCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Görünüm',
                  style: AppTextStyles.h3.copyWith(color: scheme.onSurface),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Karanlık Mod',
                        style: AppTextStyles.body.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (enabled) {
                        themeProvider.setThemeMode(
                          enabled ? ThemeMode.dark : ThemeMode.light,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PPCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Uygulama',
                  style: AppTextStyles.h3.copyWith(color: scheme.onSurface),
                ),
                const SizedBox(height: 4),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Sürüm'),
                  trailing: Text('1.0.0'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
