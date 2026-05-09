import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/pp_button.dart';
import '../../../shared/widgets/pp_card.dart';
import '../../../shared/widgets/pp_text_field.dart';
import '../widgets/friend_card.dart';

final mockFriends = [
  {
    'id': '1',
    'name': 'Ahmet Yılmaz',
    'weeklyPages': 124,
    'streak': 8,
    'totalBooks': 12,
    'avatarColor': 0xFF6C63FF,
  },
  {
    'id': '2',
    'name': 'Zeynep Kaya',
    'weeklyPages': 89,
    'streak': 15,
    'totalBooks': 24,
    'avatarColor': 0xFF22C55E,
  },
  {
    'id': '3',
    'name': 'Mert Demir',
    'weeklyPages': 210,
    'streak': 3,
    'totalBooks': 7,
    'avatarColor': 0xFFF59E0B,
  },
];

final mockRequests = [
  {
    'id': '4',
    'name': 'Elif Şahin',
    'avatarColor': 0xFFEF4444,
  },
];

const myWeeklyPages = 156;
const myStreak = 5;

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  late List<Map<String, Object?>> _requests;
  final Set<String> _sentRequests = <String>{};
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requests = mockRequests.cast<Map<String, Object?>>().map((e) => Map<String, Object?>.from(e)).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, Object?> _topFriend() {
    final friends = mockFriends.cast<Map<String, Object?>>();
    friends.sort((a, b) => ((b['weeklyPages'] as int? ?? 0)).compareTo((a['weeklyPages'] as int? ?? 0)));
    return friends.isEmpty ? const {} : friends.first;
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
    final top = _topFriend();
    final topName = (top['name'] as String?) ?? '—';
    final topWeekly = (top['weeklyPages'] as int?) ?? 0;
    final topStreak = (top['streak'] as int?) ?? 0;
    final topColor = Color((top['avatarColor'] as int?) ?? 0xFF6C63FF);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sosyal'),
          actions: [
            IconButton(
              tooltip: 'Ara',
              onPressed: () {},
              icon: const Icon(Icons.search),
            ),
          ],
          bottom: TabBar(
            labelStyle: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Arkadaşlar'),
              Tab(text: 'İstekler'),
              Tab(text: 'Keşfet'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Friends
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                PPCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bu Hafta', style: AppTextStyles.h3.copyWith(color: scheme.onSurface)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _CompareTile(
                              name: 'Sen',
                              pages: myWeeklyPages,
                              streak: myStreak,
                              color: AppColors.primary,
                              initials: 'ME',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _CompareTile(
                              name: topName.split(' ').first,
                              pages: topWeekly,
                              streak: topStreak,
                              color: topColor,
                              initials: _initials(topName),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ...mockFriends.cast<Map<String, Object?>>().map((f) {
                  final id = (f['id'] as String?) ?? '';
                  final name = (f['name'] as String?) ?? '';
                  final weekly = (f['weeklyPages'] as int?) ?? 0;
                  final streak = (f['streak'] as int?) ?? 0;
                  final color = Color((f['avatarColor'] as int?) ?? 0xFF6C63FF);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FriendCard(
                      name: name,
                      weeklyPages: weekly,
                      streak: streak,
                      avatarColor: color,
                      onTap: () => context.go('/social/$id'),
                    ),
                  );
                }),
              ],
            ),

            // Requests
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_requests.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Text(
                        'Bekleyen istek yok',
                        style: AppTextStyles.body.copyWith(color: scheme.onSurface.withValues(alpha: 0.7)),
                      ),
                    ),
                  )
                else
                  ..._requests.map((r) {
                    final id = (r['id'] as String?) ?? '';
                    final name = (r['name'] as String?) ?? '';
                    final color = Color((r['avatarColor'] as int?) ?? 0xFF6C63FF);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PPCard(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: color,
                                  child: Text(
                                    _initials(name),
                                    style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: AppTextStyles.body.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: PPButton(
                                    label: 'Kabul Et',
                                    onPressed: () => setState(() => _requests.removeWhere((e) => e['id'] == id)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: PPButton(
                                    label: 'Reddet',
                                    variant: PPButtonVariant.secondary,
                                    onPressed: () => setState(() => _requests.removeWhere((e) => e['id'] == id)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),

            // Explore
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                PPTextField(
                  label: 'Ara',
                  hint: 'Kullanıcı adı ara...',
                  controller: _searchController,
                  prefixIcon: Icons.search,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                ...const [
                  {'name': 'Can Öztürk', 'avatarColor': 0xFF6C63FF},
                  {'name': 'Selin Arslan', 'avatarColor': 0xFF22C55E},
                ].map((u) {
                  final name = u['name'] as String;
                  final color = Color(u['avatarColor'] as int);
                  final sent = _sentRequests.contains(name);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PPCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: color,
                            child: Text(
                              _initials(name),
                              style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(name, style: AppTextStyles.body.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w600)),
                          ),
                          PPButton(
                            label: sent ? 'İstek Gönderildi ✓' : 'Arkadaş Ekle',
                            variant: PPButtonVariant.secondary,
                            onPressed: sent ? null : () => setState(() => _sentRequests.add(name)),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompareTile extends StatelessWidget {
  const _CompareTile({
    required this.name,
    required this.pages,
    required this.streak,
    required this.color,
    required this.initials,
  });

  final String name;
  final int pages;
  final int streak;
  final Color color;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: color,
                child: Text(
                  initials,
                  style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: AppTextStyles.bodySmall.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('$pages sayfa', style: AppTextStyles.h3.copyWith(color: scheme.onSurface)),
          const SizedBox(height: 2),
          Text('🔥$streak', style: AppTextStyles.caption.copyWith(color: scheme.onSurface.withValues(alpha: 0.75))),
        ],
      ),
    );
  }
}

