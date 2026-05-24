import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/exceptions/api_exceptions.dart';
import '../../../core/services/api_service.dart';
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
  final _api = ApiService();
  final _isbnController = TextEditingController();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _totalPagesController = TextEditingController();

  int _selectedCoverColor = 0xFF6C63FF;
  bool _saving = false;
  bool _searching = false;

  String? _titleError;
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

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _autofillFromIsbn() async {
    final isbn = _isbnController.text.trim();
    if (isbn.isEmpty) {
      _showError('ISBN girin');
      return;
    }

    setState(() => _searching = true);
    try {
      final result = await _api.searchBookByIsbn(isbn);
      if (!mounted) return;
      setState(() {
        _titleController.text = result['title'] as String? ?? '';
        final pages = result['total_pages'];
        if (pages is int && pages > 0) {
          _totalPagesController.text = pages.toString();
        }
        _titleError = null;
        _pagesError = null;
      });
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Kitap bilgisi alınamadı');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final pagesText = _totalPagesController.text.trim();
    final pages = int.tryParse(pagesText);
    final isbn = _isbnController.text.trim();

    setState(() {
      _titleError = title.isEmpty ? 'Kitap adı zorunlu' : null;
      _pagesError = (pages == null || pages <= 0) ? 'Toplam sayfa geçersiz' : null;
    });

    if (_titleError != null || _pagesError != null) return;

    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    try {
      await _api.createBook(
        title: title,
        totalPages: pages!,
        isbn: isbn.isEmpty ? null : isbn,
      );
      if (!mounted) return;
      navigator.pop();
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Kitap kaydedilemedi');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final busy = _saving || _searching;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitap Ekle'),
        automaticallyImplyLeading: true,
        leading: IconButton(
          tooltip: 'Geri',
          onPressed: busy ? null : () => context.pop(),
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
                  label: _searching ? 'Aranıyor...' : 'Otomatik Doldur',
                  fullWidth: true,
                  variant: PPButtonVariant.secondary,
                  onPressed: busy ? null : _autofillFromIsbn,
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
                  prefixIcon: Icons.person_outline,
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
                      onTap: busy ? null : () => setState(() => _selectedCoverColor = c),
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
                  label: _saving ? 'Kaydediliyor...' : 'Kaydet',
                  fullWidth: true,
                  onPressed: busy ? null : _save,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
