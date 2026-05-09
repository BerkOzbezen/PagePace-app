import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/pp_button.dart';
import '../../../shared/widgets/pp_card.dart';
import '../../../shared/widgets/pp_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _password2Controller = TextEditingController();

  bool _p1Hidden = true;
  bool _p2Hidden = true;

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _password2Error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _password2Controller.dispose();
    super.dispose();
  }

  void _mockRegister() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final p1 = _passwordController.text;
    final p2 = _password2Controller.text;

    setState(() {
      _nameError = name.isEmpty ? 'Ad Soyad zorunlu' : null;
      _emailError = email.isEmpty ? 'E-posta zorunlu' : null;
      _passwordError = p1.isEmpty ? 'Şifre zorunlu' : null;
      _password2Error = p2.isEmpty
          ? 'Şifre tekrar zorunlu'
          : (p1.isNotEmpty && p1 != p2)
              ? 'Şifreler eşleşmiyor'
              : null;
    });

    if (_nameError != null || _emailError != null || _passwordError != null || _password2Error != null) return;

    context.go('/books');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Geri',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(''),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Hesap Oluştur', style: AppTextStyles.h1.copyWith(color: scheme.onSurface)),
                const SizedBox(height: 12),
                PPCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PPTextField(
                        label: 'Ad Soyad',
                        hint: 'Örn. Berk Yılmaz',
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        errorText: _nameError,
                        prefixIcon: Icons.person_outline,
                        onChanged: (_) => setState(() => _nameError = null),
                      ),
                      const SizedBox(height: 12),
                      PPTextField(
                        label: 'E-posta',
                        hint: 'ornek@mail.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        errorText: _emailError,
                        prefixIcon: Icons.email_outlined,
                        onChanged: (_) => setState(() => _emailError = null),
                      ),
                      const SizedBox(height: 12),
                      PPTextField(
                        label: 'Şifre',
                        hint: '••••••••',
                        controller: _passwordController,
                        obscureText: _p1Hidden,
                        textInputAction: TextInputAction.next,
                        errorText: _passwordError,
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          tooltip: _p1Hidden ? 'Göster' : 'Gizle',
                          onPressed: () => setState(() => _p1Hidden = !_p1Hidden),
                          icon: Icon(_p1Hidden ? Icons.visibility : Icons.visibility_off),
                        ),
                        onChanged: (_) => setState(() => _passwordError = null),
                      ),
                      const SizedBox(height: 12),
                      PPTextField(
                        label: 'Şifre Tekrar',
                        hint: '••••••••',
                        controller: _password2Controller,
                        obscureText: _p2Hidden,
                        textInputAction: TextInputAction.done,
                        errorText: _password2Error,
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          tooltip: _p2Hidden ? 'Göster' : 'Gizle',
                          onPressed: () => setState(() => _p2Hidden = !_p2Hidden),
                          icon: Icon(_p2Hidden ? Icons.visibility : Icons.visibility_off),
                        ),
                        onChanged: (_) => setState(() => _password2Error = null),
                      ),
                      const SizedBox(height: 12),
                      PPButton(
                        label: 'Kayıt Ol',
                        fullWidth: true,
                        onPressed: _mockRegister,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Zaten hesabın var mı? ', style: AppTextStyles.bodySmall.copyWith(color: scheme.onSurface.withValues(alpha: 0.75))),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: Text('Giriş Yap', style: AppTextStyles.bodySmall.copyWith(color: scheme.primary, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mock kayıt: Form doluysa /books’a yönlenir.',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                        textAlign: TextAlign.center,
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

