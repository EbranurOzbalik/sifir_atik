import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sifir_atik/services/auth_service.dart';
import 'package:sifir_atik/services/session_preferences.dart';

import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  final _sessionPreferences = const SessionPreferences();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isRegisterMode = false;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  int get _passwordStrength {
    final password = _passwordController.text;
    var score = 0;

    if (password.length >= 6) score++;
    if (password.length >= 10) score++;
    if (RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'[0-9!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    return score;
  }

  String get _passwordStrengthLabel => switch (_passwordStrength) {
    0 || 1 => 'Zayıf',
    2 => 'Orta',
    3 => 'İyi',
    _ => 'Güçlü',
  };

  Future<void> _loadRememberMe() async {
    if (Firebase.apps.isEmpty) return;

    final rememberMe = await _sessionPreferences.getRememberMe();
    if (mounted) setState(() => _rememberMe = rememberMe);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'E-posta adresi boş bırakılamaz.';
    }

    final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailPattern.hasMatch(email)) {
      return 'Geçerli bir e-posta adresi girin.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre boş bırakılamaz.';
    }

    if (value.length < 6) {
      return 'Şifre en az 6 karakter olmalıdır.';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (!_isRegisterMode) return null;

    if (value == null || value.isEmpty) {
      return 'Şifre tekrarını yazın.';
    }

    if (value != _passwordController.text) {
      return 'Şifreler aynı olmalıdır.';
    }

    return null;
  }

  Future<void> _submit() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      if (_isRegisterMode) {
        await _authService.registerWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        await _sessionPreferences.setRememberMe(_rememberMe);

        if (mounted) _openHomePage();
        return;
      }

      await _authService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await _sessionPreferences.setRememberMe(_rememberMe);

      if (mounted) _openHomePage();
    } on AuthServiceException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('Giriş sırasında bir hata oluştu.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openHomePage() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomePage()),
    );
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await _authService.signInWithGoogle();
      await _sessionPreferences.setRememberMe(_rememberMe);

      if (mounted) _openHomePage();
    } on AuthServiceException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('Google ile giriş sırasında bir hata oluştu.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    if (_isLoading) return;

    final emailError = _validateEmail(_emailController.text);
    if (emailError != null) {
      _showMessage('Önce geçerli bir e-posta adresi yazın.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.sendPasswordResetEmail(_emailController.text.trim());

      if (mounted) {
        _showMessage('Şifre sıfırlama e-postası gönderildi.');
      }
    } on AuthServiceException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('Şifre sıfırlama sırasında bir hata oluştu.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  void _toggleAuthMode() {
    FocusScope.of(context).unfocus();
    _formKey.currentState?.reset();

    setState(() {
      _isRegisterMode = !_isRegisterMode;
      _confirmPasswordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight > 40
                      ? constraints.maxHeight - 40
                      : 0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Header(
                            colorScheme: colorScheme,
                            isRegisterMode: _isRegisterMode,
                          ),
                          const SizedBox(height: 40),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            autocorrect: false,
                            validator: _validateEmail,
                            decoration: const InputDecoration(
                              labelText: 'E-posta adresi',
                              hintText: 'ornek@eposta.com',
                              prefixIcon: Icon(Icons.email_outlined),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: _isRegisterMode
                                ? TextInputAction.next
                                : TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            validator: _validatePassword,
                            onChanged: (_) => setState(() {}),
                            onFieldSubmitted: (_) {
                              if (!_isRegisterMode) _submit();
                            },
                            decoration: InputDecoration(
                              labelText: 'Şifre',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Şifreyi göster'
                                    : 'Şifreyi gizle',
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          if (_isRegisterMode) ...[
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.newPassword],
                              validator: _validateConfirmPassword,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: 'Şifre tekrar',
                                prefixIcon: const Icon(Icons.lock_reset),
                                suffixIcon: IconButton(
                                  tooltip: _obscureConfirmPassword
                                      ? 'Şifre tekrarını göster'
                                      : 'Şifre tekrarını gizle',
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ],
                          if (_passwordController.text.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _PasswordStrengthIndicator(
                              strength: _passwordStrength,
                              label: _passwordStrengthLabel,
                              colorScheme: colorScheme,
                            ),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: CheckboxListTile(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  dense: true,
                                  title: const Text('Beni Hatırla'),
                                ),
                              ),
                              TextButton(
                                onPressed: _isLoading || _isRegisterMode
                                    ? null
                                    : _sendPasswordResetEmail,
                                child: const Text('Şifremi Unuttum?'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _isLoading ? null : _submit,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(54),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox.square(
                                    dimension: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    _isRegisterMode
                                        ? 'Hesap Oluştur'
                                        : 'Giriş Yap',
                                  ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  'veya',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 20),
                          OutlinedButton.icon(
                            onPressed: _isLoading ? null : _signInWithGoogle,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(54),
                              foregroundColor: colorScheme.onSurface,
                              side: BorderSide(color: colorScheme.outline),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            icon: const Icon(
                              Icons.g_mobiledata_rounded,
                              size: 30,
                            ),
                            label: const Text('Google ile Giriş Yap'),
                          ),
                          const SizedBox(height: 28),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                _isRegisterMode
                                    ? 'Zaten hesabın var mı?'
                                    : 'Hesabın yok mu?',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              TextButton(
                                onPressed: _isLoading ? null : _toggleAuthMode,
                                child: Text(
                                  _isRegisterMode ? 'Giriş Yap' : 'Kayıt Ol',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PasswordStrengthIndicator extends StatelessWidget {
  const _PasswordStrengthIndicator({
    required this.strength,
    required this.label,
    required this.colorScheme,
  });

  final int strength;
  final String label;
  final ColorScheme colorScheme;

  Color get _indicatorColor => switch (strength) {
    0 || 1 => colorScheme.error,
    2 => Colors.orange.shade700,
    3 => Colors.lightGreen.shade700,
    _ => colorScheme.primary,
  };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Şifre gücü: $label',
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: strength / 4,
                minHeight: 6,
                color: _indicatorColor,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: _indicatorColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.colorScheme, required this.isRegisterMode});

  final ColorScheme colorScheme;
  final bool isRegisterMode;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 160,
          height: 138,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/zero_waste_logo.png',
            semanticLabel: 'Sıfır atık görseli',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Sıfır Atık',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          isRegisterMode
              ? 'Yeni hesap oluşturup ilan paylaşmaya başlayın.'
              : 'Daha sürdürülebilir bir gelecek için\naramıza hoş geldiniz.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
