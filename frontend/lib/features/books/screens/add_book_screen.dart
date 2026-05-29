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
  final _titleSearchController = TextEditingController();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _totalPagesController = TextEditingController();

  int _selectedCoverColor = 0xFF6C63FF;
  bool _saving = false;
  bool _searchingTitle = false;
  String _coverUrl = '';
  List<Map<String, dynamic>> _titleSearchResults = [];

  String? _titleError;
  String? _pagesError;
  String _status = 'reading';

  final _colors = const [
    0xFF6C63FF,
    0xFF4B44CC,
    0xFF22C55E,
    0xFFF59E0B,
    0xFFEF4444,
    0xFF1E1E2E,
  ];

  String _isbn = '';

  @override
  void dispose() {
    _titleSearchController.dispose();
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

  int? _readPages(dynamic value) {
    if (value is int && value > 0) return value;
    if (value is num && value > 0) return value.toInt();
    return null;
  }

  Future<void> _searchByTitle() async {
    final query = _titleSearchController.text.trim();
    if (query.isEmpty) {
      _showError('Kitap adı girin');
      return;
    }

    setState(() {
      _searchingTitle = true;
      _titleSearchResults = [];
    });

    try {
      final results = await _api.searchBooksByTitle(query);
      if (!mounted) return;
      setState(() => _titleSearchResults = results);
      if (results.isEmpty) _showError('Sonuç bulunamadı');
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Arama başarısız');
    } finally {
      if (mounted) setState(() => _searchingTitle = false);
    }
  }

  void _selectTitleResult(Map<String, dynamic> result) {
    final pages = _readPages(result['total_pages']);
    final isbn = result['isbn'] as String?;
    setState(() {
      _titleController.text = result['title'] as String? ?? '';
      _authorController.text = result['author_name'] as String? ?? '';
      if (pages != null) {
        _totalPagesController.text = pages.toString();
      } else {
        _totalPagesController.clear();
      }
      _isbn = (isbn != null && isbn.isNotEmpty) ? isbn : '';
      _coverUrl = result['cover_url'] as String? ?? '';
      _titleSearchResults = [];
      _titleError = null;
      _pagesError = null;
    });
    if (pages == null) {
      _showError('Bu kitabın sayfa sayısı bulunamadı, lütfen manuel girin');
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final pagesText = _totalPagesController.text.trim();
    final pages = int.tryParse(pagesText);
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
        isbn: _isbn.isEmpty ? null : _isbn,
        coverUrl: _coverUrl.isEmpty ? null : _coverUrl,
        status: _status,
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
    final busy = _saving || _searchingTitle;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Kitap Ekle'),
        automaticallyImplyLeading: true,
        leading: IconButton(
          tooltip: 'Geri',
          onPressed: busy ? null : () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PPCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                PPTextField(
                  label: 'Kitap Adıyla Ara',
                  hint: 'Örn. Dune',
                  controller: _titleSearchController,
                  textInputAction: TextInputAction.search,
                  prefixIcon: Icons.search,
                ),
                const SizedBox(height: 10),
                PPButton(
                  label: _searchingTitle ? 'Aranıyor...' : 'Ara',
                  fullWidth: true,
                  variant: PPButtonVariant.secondary,
                  onPressed: busy ? null : _searchByTitle,
                ),
                if (_titleSearchResults.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Map<String, dynamic>>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Sonuç seç',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _titleSearchResults.map((result) {
                      final title = result['title'] as String? ?? 'Bilinmeyen';
                      final author = result['author_name'] as String? ?? '';
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: result,
                        child: Text(
                          author.isEmpty ? title : '$title — $author',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: busy
                        ? null
                        : (value) {
                            if (value != null) {
                              _selectTitleResult(value);
                            }
                          },
                  ),
                ],
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
                Text(
                  'Durum',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'reading',
                      label: Text('Şu an okuyorum'),
                    ),
                    ButtonSegment(
                      value: 'wishlist',
                      label: Text('Okumak istiyorum'),
                    ),
                  ],
                  selected: {_status},
                  onSelectionChanged: busy
                      ? null
                      : (selection) {
                          if (selection.isEmpty) return;
                          setState(() => _status = selection.first);
                        },
                ),
                const SizedBox(height: 14),
                Text(
                  'Kapak rengi',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
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
                          border: selected
                              ? Border.all(color: scheme.onSurface, width: 2)
                              : Border.all(color: scheme.outline),
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
          ),
        ),
      ),
    );
  }
}
