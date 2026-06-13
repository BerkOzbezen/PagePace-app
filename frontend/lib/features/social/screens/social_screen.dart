import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/exceptions/api_exceptions.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/book_mapper.dart';
import '../../../shared/widgets/pp_button.dart';
import '../../../shared/widgets/pp_card.dart';
import '../../../shared/widgets/pp_text_field.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final _api = ApiService();

  bool _loading = true;
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.getFriends(),
        _api.getFriendRequests(),
      ]);
      if (!mounted) return;
      setState(() {
        _friends = results[0];
        _requests = results[1];
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _friends = [];
        _requests = [];
        _loading = false;
      });
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.take(1).toString().toUpperCase();
    return '${parts.first.characters.take(1).toString().toUpperCase()}${parts.last.characters.take(1).toString().toUpperCase()}';
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  Future<void> _showAddFriendDialog() async {
    final messenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Arkadaş Ekle'),
          content: PPTextField(
            label: 'E-posta',
            hint: 'ornek@mail.com',
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () async {
                final email = controller.text.trim();
                if (email.isEmpty) return;
                Navigator.of(ctx).pop();
                try {
                  await _api.sendFriendRequest(email);
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Arkadaşlık isteği gönderildi!')),
                  );
                  _load();
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Hata: $e')),
                  );
                }
              },
              child: const Text('Gönder'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _acceptRequest(String senderUid) async {
    try {
      await _api.acceptFriendRequest(senderUid);
      if (!mounted) return;
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _rejectRequest(String senderUid) async {
    try {
      await _api.rejectFriendRequest(senderUid);
      if (!mounted) return;
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sosyal'),
        actions: [
          IconButton(
            tooltip: 'Arkadaş Ekle',
            onPressed: _showAddFriendDialog,
            icon: const Icon(Icons.person_add),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (_requests.isNotEmpty) ...[
                    Text(
                      'Gelen İstekler',
                      style: AppTextStyles.h3.copyWith(color: scheme.onSurface),
                    ),
                    const SizedBox(height: 12),
                    ..._requests.map((request) {
                      final senderUid = request['sender_uid'] as String? ?? '';
                      final name = request['sender_name'] as String? ?? 'Kullanıcı';
                      final color = Color(coverColorFromId(senderUid));
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
                                      style: AppTextStyles.body.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: AppTextStyles.body.copyWith(
                                        color: scheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
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
                                      onPressed: () => _acceptRequest(senderUid),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: PPButton(
                                      label: 'Reddet',
                                      variant: PPButtonVariant.secondary,
                                      onPressed: () => _rejectRequest(senderUid),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    'Arkadaşlar',
                    style: AppTextStyles.h3.copyWith(color: scheme.onSurface),
                  ),
                  const SizedBox(height: 12),
                  if (_friends.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Center(
                        child: Text(
                          'Henüz arkadaşın yok',
                          style: AppTextStyles.body.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    )
                  else
                    ..._friends.map((friend) {
                      final uid = friend['uid'] as String? ?? '';
                      final name = friend['display_name'] as String? ?? 'Kullanıcı';
                      final email = friend['email'] as String? ?? '';
                      final streak = _readInt(friend['current_streak']);
                      final totalPages = _readInt(friend['total_pages']);
                      final color = Color(coverColorFromId(uid));
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PPCard(
                          padding: const EdgeInsets.all(12),
                          onTap: () => context.go('/social/$uid'),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: color,
                                child: Text(
                                  _initials(name),
                                  style: AppTextStyles.body.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: AppTextStyles.body.copyWith(
                                        color: scheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (email.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        email,
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Text(
                                      '🔥 $streak günlük seri • $totalPages sayfa',
                                      style: AppTextStyles.caption.copyWith(
                                        color: scheme.onSurface.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: scheme.onSurface.withValues(alpha: 0.65),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
