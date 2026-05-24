import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/pp_button.dart';
import '../../../shared/widgets/pp_card.dart';
import '../../../shared/widgets/pp_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _passwordHidden = true;
  bool _loading = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _emailError = email.isEmpty ? 'E-posta zorunlu' : null;
      _passwordError = password.isEmpty ? 'Şifre zorunlu' : null;
    });

    if (_emailError != null || _passwordError != null) return;

    setState(() => _loading = true);
    try {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (!mounted) return;
      context.go('/books');
    } on FirebaseAuthException catch (e) {
      _showError(_authService.firebaseErrorMessage(e));
    } catch (_) {
      _showError('Giriş yapılamadı');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      await _authService.signInWithGoogle();
      if (!mounted) return;
      context.go('/books');
    } on FirebaseAuthException catch (e) {
      _showError(_authService.firebaseErrorMessage(e));
    } catch (_) {
      _showError('Google ile giriş yapılamadı');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.22),
                        AppColors.primaryDark.withValues(alpha: 0.06),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.menu_book, size: 48, color: AppColors.primary),
                      const SizedBox(height: 10),
                      ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ).createShader(bounds),
                        child: Text(
                          'PagePace',
                          style: AppTextStyles.h1.copyWith(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your reading, your pace.',
                        style: AppTextStyles.body.copyWith(color: scheme.onSurface.withValues(alpha: 0.7)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                PPCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ShadowedButton(
                        child: PPButton(
                          label: 'Google ile Giriş Yap',
                          variant: PPButtonVariant.secondary,
                          fullWidth: true,
                          leading: const Icon(Icons.g_mobiledata),
                          onPressed: _loading ? null : _signInWithGoogle,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: Divider(color: scheme.outline)),
                          const SizedBox(width: 10),
                          Text('veya', style: AppTextStyles.caption.copyWith(color: scheme.onSurface.withValues(alpha: 0.6))),
                          const SizedBox(width: 10),
                          Expanded(child: Divider(color: scheme.outline)),
                        ],
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
                        obscureText: _passwordHidden,
                        textInputAction: TextInputAction.done,
                        errorText: _passwordError,
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          tooltip: _passwordHidden ? 'Göster' : 'Gizle',
                          onPressed: () => setState(() => _passwordHidden = !_passwordHidden),
                          icon: Icon(_passwordHidden ? Icons.visibility : Icons.visibility_off),
                        ),
                        onChanged: (_) => setState(() => _passwordError = null),
                      ),
                      const SizedBox(height: 12),
                      _ShadowedButton(
                        child: PPButton(
                          label: _loading ? 'Giriş yapılıyor...' : 'Giriş Yap',
                          fullWidth: true,
                          onPressed: _loading ? null : _signIn,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Hesabın yok mu? ', style: AppTextStyles.bodySmall.copyWith(color: scheme.onSurface.withValues(alpha: 0.75))),
                          TextButton(
                            onPressed: _loading ? null : () => context.go('/register'),
                            child: Text('Kayıt Ol', style: AppTextStyles.bodySmall.copyWith(color: scheme.primary, fontWeight: FontWeight.w600)),
                          ),
                        ],
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

class _ShadowedButton extends StatelessWidget {
  const _ShadowedButton({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
