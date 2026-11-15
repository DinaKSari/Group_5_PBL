import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/session.dart';
import '../../../../core/theme_provider.dart';
import '../../../../routes.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _notificationAlertsEnabled = true;
  String? _photoPath;

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfilePhoto();
  }

  void _loadProfilePhoto() {
    final url = _currentUser?.photoURL;
    if (url != null && url.trim().isNotEmpty && File(url.trim()).existsSync()) {
      _photoPath = url.trim();
    } else {
      _photoPath = null;
    }
  }

  String get _displayName {
    final name = _currentUser?.displayName;
    if (name != null && name.trim().isNotEmpty) return name;
    final email = _currentUser?.email ?? Session.email;
    if (email != null && email.contains('@')) {
      final prefix = email.split('@').first;
      return prefix[0].toUpperCase() + prefix.substring(1);
    }
    return 'Petani Selada';
  }

  String get _email =>
      _currentUser?.email ?? Session.email ?? 'petani@smartfarming.com';

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (picked != null) {
        // Buat file avatar khusus di cache aplikasi
        final cacheDir = File(picked.path).parent.path;
        final avatarFile = File('$cacheDir/user_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await File(picked.path).copy(avatarFile.path);

        // Bersihkan file avatar lama jika ada
        if (_photoPath != null && _photoPath != avatarFile.path) {
          try {
            final old = File(_photoPath!);
            FileImage(old).evict();
            if (await old.exists()) await old.delete();
          } catch (_) {}
        }

        setState(() {
          _photoPath = avatarFile.path;
        });

        try {
          await _currentUser?.updatePhotoURL(avatarFile.path);
          await _currentUser?.reload();
        } catch (e) {
          debugPrint('[Profile] Gagal simpan photoURL di Firebase: $e');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto profil berhasil diperbarui!'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: $e')),
        );
      }
    }
  }

  Future<void> _deleteProfilePhoto() async {
    final oldPath = _photoPath;
    final currentUrl = _currentUser?.photoURL;

    // 1. Reset state segera agar UI langsung kembali ke inisial nama
    setState(() {
      _photoPath = null;
    });

    // 2. Bersihkan cache dan hapus file foto dari disk
    if (oldPath != null) {
      try {
        final file = File(oldPath);
        FileImage(file).evict();
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('[Profile] Gagal menghapus file foto: $e');
      }
    }

    if (currentUrl != null && currentUrl.isNotEmpty && currentUrl != oldPath) {
      try {
        final f = File(currentUrl);
        FileImage(f).evict();
        if (await f.exists()) {
          await f.delete();
        }
      } catch (_) {}
    }

    // 3. Clear photoURL di Firebase Auth
    try {
      await _currentUser?.updatePhotoURL('');
      await _currentUser?.reload();
    } catch (_) {
      try {
        await _currentUser?.updatePhotoURL(null);
        await _currentUser?.reload();
      } catch (_) {}
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto profil berhasil dihapus'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _showImagePickerSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF354839) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Foto Profil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF223527) : AppColors.chip,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                ),
                title: const Text('Pilih dari Galeri'),
                subtitle: const Text('Gunakan foto dari galeri HP'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF223527) : AppColors.chip,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                ),
                title: const Text('Buka Kamera'),
                subtitle: const Text('Ambil foto langsung dengan kamera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_photoPath != null && _photoPath!.isNotEmpty) ...[
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  ),
                  title: const Text('Hapus Foto Profil', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _deleteProfilePhoto();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileSheet() {
    final controller = TextEditingController(text: _displayName);
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ubah Profil',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap / Panggilan',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: TextEditingController(text: _email),
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Alamat Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  helperText: 'Email terhubung dengan akun Firebase',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          final newName = controller.text.trim();
                          if (newName.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Nama tidak boleh kosong')),
                            );
                            return;
                          }
                          setSheetState(() => isLoading = true);
                          final res = await ref
                              .read(authRepositoryProvider)
                              .updateDisplayName(newName);
                          setSheetState(() => isLoading = false);
                          if (!mounted) return;
                          Navigator.pop(ctx);
                          if (res.failure != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(res.failure!.message)),
                            );
                          } else {
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Nama profil berhasil diperbarui!'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Simpan Perubahan',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordSheet() {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ubah Kata Sandi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Masukkan kata sandi baru minimal 6 karakter untuk memperbarui akun Anda.',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: obscureNew,
                decoration: InputDecoration(
                  labelText: 'Kata Sandi Baru',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    ),
                    onPressed: () => setSheetState(() => obscureNew = !obscureNew),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Kata Sandi Baru',
                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    ),
                    onPressed: () => setSheetState(() => obscureConfirm = !obscureConfirm),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          final pass = newPasswordController.text;
                          final confirm = confirmPasswordController.text;
                          if (pass.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Kata sandi minimal 6 karakter')),
                            );
                            return;
                          }
                          if (pass != confirm) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Konfirmasi kata sandi tidak cocok')),
                            );
                            return;
                          }
                          setSheetState(() => isLoading = true);
                          final res = await ref
                              .read(authRepositoryProvider)
                              .updatePassword(pass);
                          setSheetState(() => isLoading = false);
                          if (!mounted) return;
                          Navigator.pop(ctx);
                          if (res.failure != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(res.failure!.message)),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Kata sandi berhasil diperbarui!'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Perbarui Kata Sandi',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showTermsSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF354839) : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF223527) : AppColors.chip,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.description_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Ketentuan & Layanan',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const _TermsSection(
                title: '1. Penggunaan Aplikasi',
                content:
                    'Aplikasi Smart Farming Selada Hidroponik dikembangkan untuk memantau kualitas air, nutrisi tanaman (PPM AB Mix), pH, suhu, dan kelembapan, serta menyajikan estimasi panen menggunakan model Machine Learning.',
              ),
              const _TermsSection(
                title: '2. Privasi & Data Sensor',
                content:
                    'Data pembacaan sensor dan riwayat prediksi disimpan pada database server secara aman dan hanya digunakan untuk keperluan visualisasi grafik pemantauan dan peningkatan akurasi model panen selada Anda.',
              ),
              const _TermsSection(
                title: '3. Ketentuan Model Prediksi Panen (AI)',
                content:
                    'Hasil prediksi tanggal panen dan status pertumbuhan selada merupakan estimasi berbasis model komparatif machine learning. Kondisi cuaca ekstrem atau kegagalan perangkat keras hidroponik di lapangan tetap membutuhkan evaluasi visual oleh petani.',
              ),
              const _TermsSection(
                title: '4. Hak Cipta & Hak Kelompok',
                content:
                    'Aplikasi ini merupakan bagian dari Proyek PBL Kelompok 5 (Smart Farming Hidroponik) Politeknik Negeri Batam.',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Saya Mengerti & Setuju'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showGuidanceDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.eco_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Standar Selada Hidroponik', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Nutrisi PPM: 560 – 840 ppm (Fase Vegetatif & Pembesaran)', style: TextStyle(fontSize: 13)),
            SizedBox(height: 6),
            Text('• Derajat Keasaman (pH): 5.5 – 6.5 (Optimal: 6.0)', style: TextStyle(fontSize: 13)),
            SizedBox(height: 6),
            Text('• Suhu Air/Lingkungan: 22°C – 28°C', style: TextStyle(fontSize: 13)),
            SizedBox(height: 6),
            Text('• Masa Panen Optimal: 30 – 40 Hari Setelah Tanam (HST)', style: TextStyle(fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Tentang Aplikasi', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Smart Farming Selada Hidroponik', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Versi: 1.0.0+1', style: TextStyle(color: AppColors.muted, fontSize: 13)),
            SizedBox(height: 12),
            Text('Dikembangkan oleh Group 5 PBL:', style: TextStyle(fontSize: 13)),
            SizedBox(height: 4),
            Text('• Mobile Frontend: Flutter (Clean Architecture)', style: TextStyle(fontSize: 12, color: AppColors.muted)),
            Text('• Backend Services: Laravel 11 REST API', style: TextStyle(fontSize: 12, color: AppColors.muted)),
            Text('• Machine Learning: Flask Microservice & Scikit-learn', style: TextStyle(fontSize: 12, color: AppColors.muted)),
            Text('• Cloud & Auth: Firebase Platform', style: TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Keluar Akun?', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun ini? Anda harus masuk kembali untuk memantau data kebun.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authRepositoryProvider).signOut();
              if (mounted) {
                context.go(AppRoute.login);
              }
            },
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final isDarkBackground = Theme.of(context).brightness == Brightness.dark;
    final hasCustomPhoto = _photoPath != null &&
        _photoPath!.isNotEmpty &&
        File(_photoPath!).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil Pengguna',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // 1. Kartu Header Profil
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _showImagePickerSheet,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: AppColors.chip,
                          backgroundImage: hasCustomPhoto ? FileImage(File(_photoPath!)) : null,
                          child: !hasCustomPhoto
                              ? Text(
                                  _displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'P',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                )
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDarkBackground ? const Color(0xFF1D2620) : Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          _displayName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Ubah Nama',
                        onPressed: _showEditProfileSheet,
                      ),
                    ],
                  ),
                  Text(
                    _email,
                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDarkBackground ? const Color(0xFF223527) : AppColors.chip,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Petani Hidroponik Aktif',
                          style: TextStyle(
                            color: isDarkBackground ? const Color(0xFF4ADE80) : AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. Akun & Keamanan
          const _SectionHeader(title: 'AKUN & KEAMANAN'),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const _IconBadge(icon: Icons.person_outline_rounded),
                  title: const Text('Edit Profil'),
                  subtitle: const Text('Perbarui nama tampilan'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _showEditProfileSheet,
                ),
                const Divider(height: 1, indent: 64),
                ListTile(
                  leading: const _IconBadge(icon: Icons.lock_reset_rounded),
                  title: const Text('Ubah Kata Sandi'),
                  subtitle: const Text('Perbarui kata sandi akun Anda'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _showChangePasswordSheet,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Tampilan & Notifikasi
          const _SectionHeader(title: 'TAMPILAN & PREFERENSI'),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: _IconBadge(
                    icon: isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  ),
                  title: const Text('Mode Tampilan'),
                  subtitle: Text(
                    isDarkMode ? 'Mode Gelap (Dark Mode)' : 'Mode Terang (Light Mode)',
                  ),
                  value: isDarkMode,
                  activeColor: AppColors.accent,
                  onChanged: (val) {
                    ref.read(themeModeProvider.notifier).toggle();
                  },
                ),
                const Divider(height: 1, indent: 64),
                SwitchListTile(
                  secondary: const _IconBadge(icon: Icons.notifications_active_outlined),
                  title: const Text('Notifikasi Pengingat Panen'),
                  subtitle: const Text('Peringatan saat selada siap panen (H-3 & Hari H)'),
                  value: _notificationAlertsEnabled,
                  activeColor: AppColors.accent,
                  onChanged: (val) {
                    setState(() => _notificationAlertsEnabled = val);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(val
                            ? 'Pengingat panen diaktifkan'
                            : 'Pengingat panen dinonaktifkan'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Informasi Kebun & Sensor (Saran Fitur Tambahan)
          const _SectionHeader(title: 'SISTEM KEBUN & IOT'),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const _IconBadge(icon: Icons.sensors_rounded),
                  title: const Text('Perangkat Sensor'),
                  subtitle: const Text('ESP32-SmartLettuce-01 • Greenhouse Batam'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'ONLINE',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 64),
                ListTile(
                  leading: const _IconBadge(icon: Icons.eco_outlined),
                  title: const Text('Panduan Parameter Selada'),
                  subtitle: const Text('Standar pH, PPM nutrisi AB Mix, dan suhu ideal'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _showGuidanceDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 5. Ketentuan & Bantuan
          const _SectionHeader(title: 'INFORMASI LAINNYA'),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const _IconBadge(icon: Icons.description_outlined),
                  title: const Text('Ketentuan dan Layanan'),
                  subtitle: const Text('Syarat, kebijakan privasi, dan ketentuan ML'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _showTermsSheet,
                ),
                const Divider(height: 1, indent: 64),
                ListTile(
                  leading: const _IconBadge(icon: Icons.info_outline_rounded),
                  title: const Text('Tentang Aplikasi'),
                  subtitle: const Text('Group 5 PBL • Smart Farming Selada'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _showAboutDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 6. Tombol Sign Out (Di Bawah Sendiri Berwarna Merah)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 1,
              ),
              onPressed: _confirmSignOut,
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text(
                'Keluar dari Akun (Sign Out)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.muted,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF223527) : AppColors.chip,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: AppColors.primary, size: 20),
    );
  }
}

class _TermsSection extends StatelessWidget {
  const _TermsSection({required this.title, required this.content});
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
