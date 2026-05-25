import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/exceptions/api_exceptions.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/book_mapper.dart';
import '../../../shared/widgets/pp_book_cover.dart';
import '../../../shared/widgets/pp_button.dart';
import '../../../shared/widgets/pp_card.dart';
import '../../../shared/widgets/pp_text_field.dart';

enum _TimerUiState { idle, running, paused }

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  final _api = ApiService();

  Map<String, Object?> currentBook = {
    'id': '',
    'title': 'Kitap yükleniyor...',
    'currentPage': 0,
    'totalPages': 0,
    'coverColor': 0xFF6C63FF,
  };

  _TimerUiState _state = _TimerUiState.idle;
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  DateTime? _sessionStartedAt;
  int? _sessionStartPage;

  int get _currentPage => (currentBook['currentPage'] as int?) ?? 0;
  int get _totalPages => (currentBook['totalPages'] as int?) ?? 0;
  String get _title => (currentBook['title'] as String?) ?? '';
  String? get _bookId {
    final id = currentBook['id'] as String?;
    if (id == null || id.isEmpty) return null;
    return id;
  }

  Color get _coverColor =>
      Color((currentBook['coverColor'] as int?) ?? 0xFF6C63FF);
  String get _coverUrl => (currentBook['coverUrl'] as String?) ?? '';

  @override
  void initState() {
    super.initState();
    _loadActiveBook();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadActiveBook() async {
    try {
      final raw = await _api.getBooks();
      final books = raw.map(bookFromApi).toList(growable: false);
      if (books.isEmpty || !mounted) return;

      Map<String, Object?>? active;
      for (final book in books) {
        if (book['status'] == 'reading') {
          active = book;
          break;
        }
      }
      active ??= books.first;

      setState(() => currentBook = active!);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        currentBook = {
          'id': '',
          'title': 'Aktif kitap bulunamadı',
          'currentPage': 0,
          'totalPages': 0,
          'coverColor': 0xFF6C63FF,
        };
      });
    }
  }

  void _start() {
    setState(() {
      _state = _TimerUiState.running;
      _elapsed = Duration.zero;
      _sessionStartedAt = DateTime.now().toUtc();
      _sessionStartPage = _currentPage;
    });
    _startTicker();
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _state = _TimerUiState.paused);
  }

  void _resume() {
    setState(() => _state = _TimerUiState.running);
    _startTicker();
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed += const Duration(seconds: 1);
      });
    });
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _showBookPicker() async {
    List<Map<String, Object?>> books = [];
    try {
      final raw = await _api.getBooks();
      books = raw.map(bookFromApi).toList(growable: false);
    } catch (_) {}

    if (books.isEmpty || !mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: books.length,
          itemBuilder: (_, i) {
            final book = books[i];
            final title = (book['title'] as String?) ?? '';
            final status = (book['status'] as String?) ?? '';
            final isCurrent = book['id'] == currentBook['id'];

            return ListTile(
              leading: Icon(
                Icons.menu_book,
                color: isCurrent ? AppColors.primary : null,
              ),
              title: Text(title),
              subtitle: Text(status == 'reading' ? 'Okunuyor' : status),
              selected: isCurrent,
              onTap: () {
                setState(() => currentBook = book);
                Navigator.of(ctx).pop();
              },
            );
          },
        );
      },
    );
  }

  Future<void> _finishFlow() async {
    _timer?.cancel();
    final startPage = _sessionStartPage ?? _currentPage;
    final startedAt = _sessionStartedAt;
    final bookId = _bookId;
    final elapsed = _elapsed;

    if (!mounted) return;

    final result = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => _SaveSessionPage(
          startPage: startPage,
          elapsed: elapsed,
          bookId: bookId,
          startedAt: startedAt,
          api: _api,
        ),
      ),
    );

    if (result == null || !mounted) {
      setState(() => _state = _TimerUiState.paused);
      return;
    }

    setState(() {
      currentBook['currentPage'] = result.clamp(0, _totalPages);
      _state = _TimerUiState.idle;
      _elapsed = Duration.zero;
      _sessionStartedAt = null;
      _sessionStartPage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final timerStyle = AppTextStyles.h1.copyWith(
      fontSize: _state == _TimerUiState.running ? 40 : 36,
      fontFamily: 'monospace',
      fontWeight: _state == _TimerUiState.running
          ? FontWeight.w700
          : FontWeight.w600,
      color: switch (_state) {
        _TimerUiState.paused =>
          scheme.onSurface.withValues(alpha: 0.55),
        _ => scheme.onSurface,
      },
    );

    Widget body = switch (_state) {
      _TimerUiState.idle => _IdleView(
          title: _title,
          subtitle: '$_currentPage. sayfadan devam et',
          coverColor: _coverColor,
          coverUrl: _coverUrl,
          timeText: _format(_elapsed),
          timerStyle: timerStyle,
          onStart: _start,
        ),
      _TimerUiState.running => _RunningView(
          title: _title,
          coverColor: _coverColor,
          coverUrl: _coverUrl,
          timeText: _format(_elapsed),
          timerStyle: timerStyle,
          onPause: _pause,
          onFinish: _finishFlow,
        ),
      _TimerUiState.paused => _PausedView(
          timeText: _format(_elapsed),
          timerStyle: timerStyle,
          onResume: _resume,
          onFinish: _finishFlow,
        ),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Okuma Zamanlayıcı'),
        actions: [
          if (_state == _TimerUiState.idle)
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              tooltip: 'Kitap Değiştir',
              onPressed: _showBookPicker,
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: body,
            ),
          ),
        ),
      ),
    );
  }
}

class _IdleView extends StatelessWidget {
  const _IdleView({
    required this.title,
    required this.subtitle,
    required this.coverColor,
    required this.coverUrl,
    required this.timeText,
    required this.timerStyle,
    required this.onStart,
  });

  final String title;
  final String subtitle;
  final Color coverColor;
  final String coverUrl;
  final String timeText;
  final TextStyle timerStyle;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PPBookCover(
          coverUrl: coverUrl,
          coverColor: coverColor,
          width: 160,
          height: 220,
          borderRadius: 12,
          iconSize: 56,
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: AppTextStyles.h2.copyWith(color: scheme.onSurface),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style:
              AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        Text(
          timeText,
          style: timerStyle,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.visible,
        ),
        const SizedBox(height: 18),
        PPButton(
          label: 'Okumaya Başla',
          fullWidth: true,
          leading: const Icon(Icons.play_arrow),
          onPressed: onStart,
        ),
      ],
    );
  }
}

class _RunningView extends StatelessWidget {
  const _RunningView({
    required this.title,
    required this.coverColor,
    required this.coverUrl,
    required this.timeText,
    required this.timerStyle,
    required this.onPause,
    required this.onFinish,
  });

  final String title;
  final Color coverColor;
  final String coverUrl;
  final String timeText;
  final TextStyle timerStyle;
  final VoidCallback onPause;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        PPCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              PPBookCover(
                coverUrl: coverUrl,
                coverColor: coverColor,
                width: 64,
                height: 64,
                borderRadius: 10,
                iconSize: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style:
                      AppTextStyles.h3.copyWith(color: scheme.onSurface),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.success, width: 4),
          ),
          alignment: Alignment.center,
          child: Text(
            timeText,
            style: timerStyle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.visible,
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: PPButton(
                label: 'Duraklat',
                variant: PPButtonVariant.secondary,
                onPressed: onPause,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PPButton(
                label: 'Bitir',
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                onPressed: onFinish,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PausedView extends StatelessWidget {
  const _PausedView({
    required this.timeText,
    required this.timerStyle,
    required this.onResume,
    required this.onFinish,
  });

  final String timeText;
  final TextStyle timerStyle;
  final VoidCallback onResume;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          timeText,
          style: timerStyle,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.visible,
        ),
        const SizedBox(height: 8),
        Text(
          'Duraklatıldı',
          style: AppTextStyles.body
              .copyWith(color: scheme.onSurface.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: PPButton(
                label: 'Devam Et',
                onPressed: onResume,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PPButton(
                label: 'Bitir',
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                onPressed: onFinish,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SaveSessionPage extends StatefulWidget {
  const _SaveSessionPage({
    required this.startPage,
    required this.elapsed,
    required this.bookId,
    required this.startedAt,
    required this.api,
  });

  final int startPage;
  final Duration elapsed;
  final String? bookId;
  final DateTime? startedAt;
  final ApiService api;

  @override
  State<_SaveSessionPage> createState() => _SaveSessionPageState();
}

class _SaveSessionPageState extends State<_SaveSessionPage> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.startPage.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatShort(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60);
    if (m <= 0) return '$s saniye';
    if (s == 0) return '$m dakika';
    return '$m dakika $s saniye';
  }

  Future<void> _save() async {
    final endPage = int.tryParse(_controller.text.trim());
    if (endPage == null || endPage <= widget.startPage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mevcut sayfanızdan ${widget.startPage} ileri bir sayfa girin'))
      );
      return;
    }
    if (widget.bookId == null || widget.startedAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oturum kaydedilemedi')),
      );
      return;
    }

    setState(() => _saving = true);
    final endedAt = DateTime.now().toUtc();

    try {
      await widget.api.createSession({
        'book_id': widget.bookId,
        'start_page': widget.startPage,
        'end_page': endPage,
        'duration_seconds': widget.elapsed.inSeconds,
        'started_at': widget.startedAt!.toIso8601String(),
        'ended_at': endedAt.toIso8601String(),
      });
      if (!mounted) return;
      Navigator.of(context).pop(endPage);
    } on ApiException {
      setState(() => _saving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oturum kaydedilemedi')),
      );
    } catch (_) {
      setState(() => _saving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oturum kaydedilemedi')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Oturumu Kaydet'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Kaçıncı sayfadasın?',
              style: AppTextStyles.h3.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: 12),
            PPTextField(
              label: 'Sayfa',
              controller: _controller,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.menu_book_outlined,
            ),
            const SizedBox(height: 12),
            Text(
              'Geçen süre: ${_formatShort(widget.elapsed)}',
              style: AppTextStyles.bodySmall.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            PPButton(
              label: _saving ? 'Kaydediliyor...' : 'Kaydet',
              fullWidth: true,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}