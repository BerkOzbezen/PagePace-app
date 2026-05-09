import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/pp_button.dart';
import '../../../shared/widgets/pp_card.dart';
import '../../../shared/widgets/pp_text_field.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _isbnController = TextEditingController();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _totalPagesController = TextEditingController();

  int _selectedCoverColor = 0xFF6C63FF;

  String? _titleError;
  String? _authorError;
  String? _pagesError;

  final _colors = const [
    0xFF6C63FF,
    0xFF4B44CC,
    0xFF22C55E,
    0xFFF59E0B,
    0xFFEF4444,
    0xFF1E1E2E,
  ];

  @override
  void dispose() {
    _isbnController.dispose();
    _titleController.dispose();
    _authorController.dispose();
    _totalPagesController.dispose();
    super.dispose();
  }

  void _mockAutofill() {
    setState(() {
      _titleController.text = 'Dune';
      _authorController.text = 'Frank Herbert';
      _totalPagesController.text = '412';
      _selectedCoverColor = 0xFF6C63FF;
      _titleError = null;
      _authorError = null;
      _pagesError = null;
    });
  }

  void _save() {
    final title = _titleController.text.trim();
    final author = _authorController.text.trim();
    final pagesText = _totalPagesController.text.trim();
    final pages = int.tryParse(pagesText);

    setState(() {
      _titleError = title.isEmpty ? 'Kitap adı zorunlu' : null;
      _authorError = author.isEmpty ? 'Yazar zorunlu' : null;
      _pagesError = (pages == null || pages <= 0) ? 'Toplam sayfa geçersiz' : null;
    });

    if (_titleError != null || _authorError != null || _pagesError != null) return;

    context.go('/books');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitap Ekle'),
        automaticallyImplyLeading: true,
        leading: IconButton(
          tooltip: 'Geri',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PPCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PPTextField(
                  label: 'ISBN',
                  hint: 'Örn. 978... ',
                  controller: _isbnController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.qr_code_2,
                ),
                const SizedBox(height: 10),
                PPButton(
                  label: 'Otomatik Doldur',
                  fullWidth: true,
                  variant: PPButtonVariant.secondary,
                  onPressed: _mockAutofill,
                ),
                const SizedBox(height: 14),
                PPTextField(
                  label: 'Kitap Adı',
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  errorText: _titleError,
                  prefixIcon: Icons.menu_book_outlined,
                  onChanged: (_) => setState(() => _titleError = null),
                ),
                const SizedBox(height: 12),
                PPTextField(
                  label: 'Yazar',
                  controller: _authorController,
                  textInputAction: TextInputAction.next,
                  errorText: _authorError,
                  prefixIcon: Icons.person_outline,
                  onChanged: (_) => setState(() => _authorError = null),
                ),
                const SizedBox(height: 12),
                PPTextField(
                  label: 'Toplam Sayfa',
                  controller: _totalPagesController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  errorText: _pagesError,
                  prefixIcon: Icons.format_list_numbered,
                  onChanged: (_) => setState(() => _pagesError = null),
                ),
                const SizedBox(height: 14),
                Text('Kapak rengi', style: AppTextStyles.bodySmall.copyWith(color: scheme.onSurface.withValues(alpha: 0.75))),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _colors.map((c) {
                    final selected = c == _selectedCoverColor;
                    return InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => setState(() => _selectedCoverColor = c),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                          border: selected ? Border.all(color: scheme.onSurface, width: 2) : Border.all(color: scheme.outline),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                PPButton(
                  label: 'Kaydet',
                  fullWidth: true,
                  onPressed: _save,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mock kayıt: Kaydet’e basınca /books’a döner.',
            style: AppTextStyles.caption.copyWith(color: scheme.onSurface.withValues(alpha: 0.6)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

