import 'package:flutter/material.dart';
import 'package:rempah_nusantara/config/app_theme.dart';
import 'package:rempah_nusantara/services/preferences_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _isLoading = true;

  // Notification preferences
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _orderUpdates = true;
  bool _promotions = true;
  bool _newProducts = false;
  bool _priceDrops = false;
  bool _restock = true;
  bool _messages = true;
  bool _reviews = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await PreferencesService.getNotificationPreferences();

      if (mounted) {
        setState(() {
          _pushNotifications = prefs['push_notifications'] ?? true;
          _emailNotifications = prefs['email_notifications'] ?? true;
          _orderUpdates = prefs['order_updates'] ?? true;
          _promotions = prefs['promotions'] ?? true;
          _newProducts = prefs['new_products'] ?? false;
          _priceDrops = prefs['price_drops'] ?? false;
          _restock = prefs['restock'] ?? true;
          _messages = prefs['messages'] ?? true;
          _reviews = prefs['reviews'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading notification preferences: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _savePreference(String key, bool value) async {
    try {
      await PreferencesService.setNotificationPreference(key, value);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Pengaturan disimpan'),
            backgroundColor: AppColors.success,
            duration: const Duration(milliseconds: 800),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error saving preference: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pengaturan Notifikasi',
          style: AppTextStyles.heading3.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Metode Notifikasi',
                    children: [
                      _buildNotificationTile(
                        icon: Icons.notifications_active_outlined,
                        title: 'Push Notifications',
                        subtitle: 'Terima notifikasi push di perangkat',
                        value: _pushNotifications,
                        onChanged: (value) {
                          setState(() => _pushNotifications = value);
                          _savePreference('push_notifications', value);
                        },
                      ),
                      _buildNotificationTile(
                        icon: Icons.email_outlined,
                        title: 'Email Notifications',
                        subtitle: 'Terima notifikasi via email',
                        value: _emailNotifications,
                        onChanged: (value) {
                          setState(() => _emailNotifications = value);
                          _savePreference('email_notifications', value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Notifikasi Pesanan',
                    children: [
                      _buildNotificationTile(
                        icon: Icons.shopping_bag_outlined,
                        title: 'Update Pesanan',
                        subtitle: 'Status pesanan, pengiriman, dll',
                        value: _orderUpdates,
                        onChanged: (value) {
                          setState(() => _orderUpdates = value);
                          _savePreference('order_updates', value);
                        },
                      ),
                      _buildNotificationTile(
                        icon: Icons.chat_outlined,
                        title: 'Pesan',
                        subtitle: 'Pesan dari penjual atau pembeli',
                        value: _messages,
                        onChanged: (value) {
                          setState(() => _messages = value);
                          _savePreference('messages', value);
                        },
                      ),
                      _buildNotificationTile(
                        icon: Icons.star_outline,
                        title: 'Review & Rating',
                        subtitle: 'Pengingat untuk memberikan review',
                        value: _reviews,
                        onChanged: (value) {
                          setState(() => _reviews = value);
                          _savePreference('reviews', value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Notifikasi Produk',
                    children: [
                      _buildNotificationTile(
                        icon: Icons.new_releases_outlined,
                        title: 'Produk Baru',
                        subtitle: 'Produk rempah baru tersedia',
                        value: _newProducts,
                        onChanged: (value) {
                          setState(() => _newProducts = value);
                          _savePreference('new_products', value);
                        },
                      ),
                      _buildNotificationTile(
                        icon: Icons.trending_down_outlined,
                        title: 'Penurunan Harga',
                        subtitle: 'Diskon & promo produk favorit',
                        value: _priceDrops,
                        onChanged: (value) {
                          setState(() => _priceDrops = value);
                          _savePreference('price_drops', value);
                        },
                      ),
                      _buildNotificationTile(
                        icon: Icons.inventory_2_outlined,
                        title: 'Stok Tersedia',
                        subtitle: 'Produk kembali tersedia',
                        value: _restock,
                        onChanged: (value) {
                          setState(() => _restock = value);
                          _savePreference('restock', value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Notifikasi Lainnya',
                    children: [
                      _buildNotificationTile(
                        icon: Icons.local_offer_outlined,
                        title: 'Promosi & Penawaran',
                        subtitle: 'Voucher, diskon, dan penawaran khusus',
                        value: _promotions,
                        onChanged: (value) {
                          setState(() => _promotions = value);
                          _savePreference('promotions', value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildResetButton(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kelola notifikasi yang ingin Anda terima',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pengaturan akan tersimpan otomatis',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
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
            children: children
                .asMap()
                .entries
                .expand(
                  (entry) => [
                    entry.value,
                    if (entry.key < children.length - 1)
                      const Divider(height: 1, indent: 72),
                  ],
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationTile({
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

  Widget _buildResetButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _resetToDefaults,
        icon: const Icon(Icons.restore),
        label: const Text('Reset ke Default'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          side: const BorderSide(color: AppColors.border, width: 1),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
        ),
      ),
    );
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        ),
        title: Text(
          'Reset Pengaturan',
          style: AppTextStyles.heading3.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'Kembalikan semua pengaturan notifikasi ke default?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: AppTextStyles.button.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Reset to defaults
              await PreferencesService.resetNotificationPreferences();

              // Reload preferences
              await _loadPreferences();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Pengaturan direset ke default'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
