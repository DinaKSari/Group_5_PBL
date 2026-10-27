import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../routes.dart';
import '../../../../core/app_colors.dart';
import '../providers/auth_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'petani@smartfarming.id');
  final _passwordController = TextEditingController(text: 'selada2026');
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final outcome = await ref.read(authRepositoryProvider).signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    final failure = outcome.failure;
    if (!outcome.signedIn || failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login gagal: ${failure?.message ?? 'akun tidak dikenali'}'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Text('🥬', style: TextStyle(fontSize: 18)),
            SizedBox(width: 10),
            Text('Selamat Datang, Petani Selada! Mari pantau panenmu.'),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );

    context.go(AppRoute.home);
  }

  void _handleQuickDemoLogin() {
    _emailController.text = 'petani@smartfarming.id';
    _passwordController.text = 'selada2026';
    _handleLogin();
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.help_outline_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Lupa Kata Sandi?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Untuk versi demo PBL ini, Anda dapat langsung masuk dengan kredensial default:\n\n'
          '📧 Email: petani@smartfarming.id\n'
          '🔑 Sandi: selada2026\n\n'
          'Atau gunakan tombol "Masuk Cepat Mode Demo".',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.darkBtn,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.border),
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.text, size: 20),
          onPressed: () => context.go(AppRoute.splash),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Fun Illustrated Badge
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.sunGradientStart, AppColors.sunGradientEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x28FFA726),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('👨‍🌾', style: TextStyle(fontSize: 42)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Selamat Datang, Petani!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Kelola kebun & pantau panen selada dengan mudah',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                  const SizedBox(height: 24),

                  // Login Form Card
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Masuk ke Akun Kebun',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Email tidak boleh kosong';
                                if (!val.contains('@')) return 'Format email tidak valid';
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: 'Email Petani',
                                hintText: 'petani@smartfarming.id',
                                prefixIcon: const Icon(Icons.alternate_email_rounded, color: AppColors.accent, size: 20),
                                border: border,
                                enabledBorder: border,
                                focusedBorder: border.copyWith(
                                  borderSide: const BorderSide(color: AppColors.accent, width: 1.8),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFFAFBFA),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleLogin(),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Kata sandi tidak boleh kosong';
                                if (val.length < 6) return 'Minimal 6 karakter';
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: 'Kata Sandi',
                                prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.accent, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: AppColors.muted,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                border: border,
                                enabledBorder: border,
                                focusedBorder: border.copyWith(
                                  borderSide: const BorderSide(color: AppColors.accent, width: 1.8),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFFAFBFA),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Remember Me & Forgot Password
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        activeColor: AppColors.accent,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                        onChanged: (val) => setState(() => _rememberMe = val ?? true),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Ingat saya', style: TextStyle(fontSize: 12, color: AppColors.text)),
                                  ],
                                ),
                                TextButton(
                                  onPressed: _showForgotPasswordDialog,
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.accent,
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                  ),
                                  child: const Text('Lupa Sandi?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Dark Pill Button
                            FilledButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.darkBtn,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('Masuk ke Kebun', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward_rounded, size: 18),
                                      ],
                                    ),
                            ),
                            const SizedBox(height: 12),

                            // Quick Demo Button
                            OutlinedButton.icon(
                              onPressed: _isLoading ? null : _handleQuickDemoLogin,
                              icon: const Icon(Icons.flash_on_rounded, size: 16, color: AppColors.warn),
                              label: const Text('Masuk Cepat Mode Demo'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.text,
                                side: const BorderSide(color: AppColors.border),
                                minimumSize: const Size.fromHeight(46),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'PBL Kelompok 5 • D4 Teknik Informatika TI-3G\nAplikasi Prediksi Waktu Panen Selada',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppColors.muted, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
