import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rempah_nusantara/config/app_theme.dart';
import 'package:rempah_nusantara/services/api_service.dart';
import 'package:rempah_nusantara/services/preferences_service.dart';
import 'package:rempah_nusantara/widgets/bottom_nav_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  bool _darkMode = false;
  String _selectedLanguage = 'id';
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      // Load dark mode preference
      final darkMode = await PreferencesService.getDarkMode();
      final language = await PreferencesService.getLanguage();

      String? userRole;
      if (ApiService.isAuthenticated && ApiService.currentUserId != null) {
        try {
          final user = await ApiService.getCurrentUser();
          userRole = user['role'] as String?;
        } catch (e) {
          print('Error loading user: $e');
        }
      }

      if (mounted) {
        setState(() {
          _darkMode = darkMode;
          _selectedLanguage = language;
          _userRole = userRole;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading settings: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleDarkMode(bool value) async {
    setState(() => _darkMode = value);

    try {
      await PreferencesService.setDarkMode(value);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'Mode gelap diaktifkan. Restart aplikasi untuk menerapkan.'
                  : 'Mode terang diaktifkan. Restart aplikasi untuk menerapkan.',
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error saving dark mode preference: $e');
      // Revert on error
      if (mounted) {
        setState(() => _darkMode = !value);
      }
    }
  }

  String _getLanguageDisplayName(String code) {
    switch (code) {
      case 'id':
        return 'Bahasa Indonesia';
      case 'en':
        return 'English';
      case 'jv':
        return 'Basa Jawa';
      case 'su':
        return 'Basa Sunda';
      default:
        return 'Bahasa Indonesia';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeader(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildGeneralSection(),
                            const SizedBox(height: 24),
                            if (ApiService.isAuthenticated)
                              _buildAccountSection(),
                            if (ApiService.isAuthenticated)
                              const SizedBox(height: 24),
                            _buildAboutSection(),
                            if (ApiService.isAuthenticated) ...[
                              const SizedBox(height: 32),
                              _buildDangerZone(),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Align(
                  alignment: Alignment.bottomCenter,
                  child: BottomNavBar(currentRoute: '/settings'),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(
                        AppSizes.radiusMedium,
                      ),
                    ),
                    child: const Icon(
                      Icons.settings_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Pengaturan',
                      style: AppTextStyles.heading2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Kelola preferensi dan akun Anda',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Umum',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSettingsItem(
                icon: Icons.notifications_outlined,
                title: 'Notifikasi',
                subtitle: 'Atur preferensi notifikasi',
                onTap: () => context.push('/notification-settings'),
              ),
              const Divider(height: 1, indent: 72),
              _buildSettingsItem(
                icon: Icons.language_outlined,
                title: 'Bahasa',
                subtitle: _getLanguageDisplayName(_selectedLanguage),
                onTap: () async {
                  await context.push('/language');
                  // Reload language setting after returning
                  final language = await PreferencesService.getLanguage();
                  if (mounted) {
                    setState(() => _selectedLanguage = language);
                  }
                },
              ),
              const Divider(height: 1, indent: 72),
              _buildSettingsSwitchItem(
                icon: Icons.dark_mode_outlined,
                title: 'Mode Gelap',
                subtitle: _darkMode ? 'Aktif' : 'Nonaktif',
                value: _darkMode,
                onChanged: _toggleDarkMode,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Akun',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSettingsItem(
                icon: Icons.person_outline,
                title: 'Edit Profil',
                subtitle: 'Ubah informasi profil Anda',
                onTap: () => context.push('/edit-profile'),
              ),
              const Divider(height: 1, indent: 72),
              _buildSettingsItem(
                icon: Icons.location_on_outlined,
                title: 'Alamat',
                subtitle: 'Kelola alamat pengiriman',
                onTap: () => context.push('/address'),
              ),
              const Divider(height: 1, indent: 72),
              _buildSettingsItem(
                icon: Icons.store_outlined,
                title: 'Kelola Produk',
                subtitle: 'Jual produk rempah Anda',
                onTap: () => context.push('/manage-products'),
              ),
              // Admin Panel - only show for admin users
              if (_userRole == 'admin') ...[
                const Divider(height: 1, indent: 72),
                _buildSettingsItem(
                  icon: Icons.admin_panel_settings,
                  title: 'Admin Panel',
                  subtitle: 'Kelola pengguna, produk & pesanan',
                  onTap: () => context.push('/admin'),
                  iconColor: Colors.deepOrange,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Bantuan & Informasi',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSettingsItem(
                icon: Icons.help_outline,
                title: 'Pusat Bantuan',
                subtitle: 'FAQ dan dukungan pelanggan',
                onTap: () => context.push('/help-center'),
              ),
              const Divider(height: 1, indent: 72),
              _buildSettingsItem(
                icon: Icons.privacy_tip_outlined,
                title: 'Kebijakan Privasi',
                subtitle: 'Informasi privasi dan data',
                onTap: () => context.push('/privacy-policy'),
              ),
              const Divider(height: 1, indent: 72),
              _buildSettingsItem(
                icon: Icons.description_outlined,
                title: 'Syarat & Ketentuan',
                subtitle: 'Ketentuan penggunaan aplikasi',
                onTap: () => context.push('/privacy-policy'),
              ),
              const Divider(height: 1, indent: 72),
              _buildSettingsItem(
                icon: Icons.info_outline,
                title: 'Tentang Aplikasi',
                subtitle: 'Versi 1.0.0',
                onTap: _showAboutDialog,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDangerZone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Zona Berbahaya',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            border: Border.all(
              color: AppColors.error.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSettingsItem(
                icon: Icons.logout,
                title: 'Keluar',
                subtitle: 'Keluar dari akun Anda',
                iconColor: AppColors.error,
                textColor: AppColors.error,
                onTap: _showLogoutDialog,
              ),
              const Divider(height: 1, indent: 72),
              _buildSettingsItem(
                icon: Icons.delete_forever_outlined,
                title: 'Hapus Akun',
                subtitle: 'Hapus akun secara permanen',
                iconColor: AppColors.error,
                textColor: AppColors.error,
                onTap: _showDeleteAccountDialog,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
        child: Icon(icon, color: iconColor ?? AppColors.primary, size: 24),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyLarge.copyWith(
          fontWeight: FontWeight.w600,
          color: textColor ?? AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: textColor ?? AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSettingsSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      secondary: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: value
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.textSecondary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
        child: Icon(
          icon,
          color: value ? AppColors.primary : AppColors.textSecondary,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyLarge.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
              child: const Icon(
                Icons.spa_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ReNusa',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Rempah Nusantara',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Versi 1.0.0',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Platform marketplace rempah dan resep tradisional Indonesia (Kelompok 3)',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '© 2026 ReNusa',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tutup',
              style: AppTextStyles.button.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    // Save parent context before showing dialog
    final parentContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
              child: const Icon(Icons.logout, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            Text(
              'Keluar',
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun Anda?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Batal',
              style: AppTextStyles.button.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              // Close dialog first
              Navigator.pop(dialogContext);

              // Logout
              await ApiService.logout();

              // Navigate using parent context (not dialog context)
              if (mounted) {
                parentContext.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    // Save parent context before showing dialog
    final parentContext = context;
    final TextEditingController confirmController = TextEditingController();
    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                ),
                child: const Icon(
                  Icons.delete_forever_outlined,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Hapus Akun',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tindakan ini tidak dapat dibatalkan!',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Menghapus akun akan:\n'
                  '• Menghapus semua data pribadi Anda\n'
                  '• Membatalkan pesanan yang sedang berjalan\n'
                  '• Menghapus riwayat transaksi\n'
                  '• Menghapus semua konten yang Anda buat\n\n'
                  'Ketik "HAPUS" untuk mengkonfirmasi:',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  enabled: !isDeleting,
                  decoration: InputDecoration(
                    hintText: 'Ketik HAPUS',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppSizes.radiusMedium,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppSizes.radiusMedium,
                      ),
                      borderSide: const BorderSide(
                        color: AppColors.error,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isDeleting
                  ? null
                  : () {
                      confirmController.dispose();
                      Navigator.pop(dialogContext);
                    },
              child: Text(
                'Batal',
                style: AppTextStyles.button.copyWith(
                  color: isDeleting
                      ? AppColors.textSecondary.withOpacity(0.5)
                      : AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isDeleting
                  ? null
                  : () async {
                      if (confirmController.text.toUpperCase() != 'HAPUS') {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text('Ketik "HAPUS" untuk mengkonfirmasi'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isDeleting = true);

                      try {
                        await ApiService.deleteAccount(
                          confirmText: confirmController.text,
                        );

                        confirmController.dispose();

                        if (mounted) {
                          // Close dialog first
                          Navigator.pop(dialogContext);

                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            const SnackBar(
                              content: Text('Akun berhasil dihapus'),
                              backgroundColor: AppColors.success,
                            ),
                          );

                          // Navigate using parent context (not dialog context)
                          parentContext.go('/login');
                        }
                      } catch (e) {
                        setDialogState(() => isDeleting = false);

                        if (mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Gagal menghapus akun: ${e.toString().replaceAll('Exception: ', '')}',
                              ),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.error.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                ),
              ),
              child: isDeleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Hapus Akun'),
            ),
          ],
        ),
      ),
    );
  }
}
