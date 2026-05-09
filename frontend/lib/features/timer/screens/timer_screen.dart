import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
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
  final currentBook = <String, Object?>{
    'title': 'Dune',
    'currentPage': 180,
    'totalPages': 412,
    'coverColor': 0xFF6C63FF,
  };

  _TimerUiState _state = _TimerUiState.idle;
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _pulse = false;

  int get _currentPage => (currentBook['currentPage'] as int?) ?? 0;
  int get _totalPages => (currentBook['totalPages'] as int?) ?? 0;
  String get _title => (currentBook['title'] as String?) ?? '';
  Color get _coverColor => Color((currentBook['coverColor'] as int?) ?? 0xFF6C63FF);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _state = _TimerUiState.running;
      _elapsed = Duration.zero;
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

  void _resetToIdle() {
    _timer?.cancel();
    setState(() {
      _state = _TimerUiState.idle;
      _elapsed = Duration.zero;
      _pulse = false;
    });
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed += const Duration(seconds: 1);
        _pulse = !_pulse;
      });
    });
  }

  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${two(h)}:${two(m)}:${two(s)}';
  }

  String _formatShort(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60);
    if (m <= 0) return '$s saniye';
    if (s == 0) return '$m dakika';
    return '$m dakika $s saniye';
  }

  Future<void> _finishFlow() async {
    _timer?.cancel();
    final startPage = _currentPage;
    final controller = TextEditingController(text: startPage.toString());

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Kaçıncı sayfadasın?', style: AppTextStyles.h3.copyWith(color: scheme.onSurface)),
              const SizedBox(height: 12),
              PPTextField(
                label: 'Sayfa',
                controller: controller,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.menu_book_outlined,
              ),
              const SizedBox(height: 12),
              Text(
                'Geçen süre: ${_formatShort(_elapsed)}',
                style: AppTextStyles.bodySmall.copyWith(color: scheme.onSurface.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 14),
              PPButton(
                label: 'Kaydet',
                fullWidth: true,
                onPressed: () => Navigator.of(context).pop(true),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('İptal', style: AppTextStyles.bodySmall.copyWith(color: scheme.onSurface.withValues(alpha: 0.75))),
              ),
            ],
          ),
        );
      },
    );

    final endPage = int.tryParse(controller.text.trim()) ?? startPage;
    controller.dispose();

    if (saved != true || !mounted) {
      setState(() => _state = _TimerUiState.paused);
      return;
    }

    final pagesRead = (endPage - startPage).clamp(0, 99999);
    setState(() => currentBook['currentPage'] = endPage.clamp(0, _totalPages));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Oturum kaydedildi — $pagesRead sayfa, ${_elapsed.inMinutes} dk'),
      ),
    );

    _resetToIdle();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final timerStyle = AppTextStyles.h1.copyWith(
      fontSize: 48,
      fontFamily: 'monospace',
      fontWeight: FontWeight.w600,
      color: switch (_state) {
        _TimerUiState.paused => scheme.onSurface.withValues(alpha: 0.55),
        _ => scheme.onSurface,
      },
    );

    Widget body = switch (_state) {
      _TimerUiState.idle => _IdleView(
          title: _title,
          subtitle: '$_currentPage. sayfadan devam et',
          coverColor: _coverColor,
          timeText: _format(_elapsed),
          timerStyle: timerStyle,
          onStart: _start,
        ),
      _TimerUiState.running => _RunningView(
          title: _title,
          coverColor: _coverColor,
          timeText: _format(_elapsed),
          timerStyle: timerStyle,
          pulseOn: _pulse,
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
      appBar: AppBar(title: const Text('Okuma Zamanlayıcı')),
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
    required this.timeText,
    required this.timerStyle,
    required this.onStart,
  });

  final String title;
  final String subtitle;
  final Color coverColor;
  final String timeText;
  final TextStyle timerStyle;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 160,
            height: 220,
            color: coverColor,
            alignment: Alignment.center,
            child: Icon(Icons.menu_book, size: 56, color: scheme.onPrimary.withValues(alpha: 0.9)),
          ),
        ),
        const SizedBox(height: 14),
        Text(title, style: AppTextStyles.h2.copyWith(color: scheme.onSurface), textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(subtitle, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
        const SizedBox(height: 18),
        Text(timeText, style: timerStyle),
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
    required this.timeText,
    required this.timerStyle,
    required this.pulseOn,
    required this.onPause,
    required this.onFinish,
  });

  final String title;
  final Color coverColor;
  final String timeText;
  final TextStyle timerStyle;
  final bool pulseOn;
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
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 64,
                  height: 64,
                  color: coverColor,
                  alignment: Alignment.center,
                  child: Icon(Icons.menu_book, color: scheme.onPrimary.withValues(alpha: 0.9)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.h3.copyWith(color: scheme.onSurface),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        AnimatedContainer(
          duration: const Duration(milliseconds: 650),
          width: pulseOn ? 220 : 200,
          height: pulseOn ? 220 : 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.success.withValues(alpha: pulseOn ? 0.55 : 0.25),
              width: 10,
            ),
          ),
          alignment: Alignment.center,
          child: Text(timeText, style: timerStyle),
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
        Text(timeText, style: timerStyle),
        const SizedBox(height: 8),
        Text('Duraklatıldı', style: AppTextStyles.body.copyWith(color: scheme.onSurface.withValues(alpha: 0.7))),
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

