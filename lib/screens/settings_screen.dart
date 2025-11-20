import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/widgets/bottom_nav_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final User? _user = Supabase.instance.client.auth.currentUser;
  String? _userRole;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Panggil _getProfile setiap kali dependensi berubah,
    // yang juga terjadi saat kita kembali ke halaman ini.
    // Ini memastikan data peran (role) selalu terbaru.
    if (mounted) {
      _getProfile();
    }
  }

  Future<void> _getProfile() async {
    setState(() {
      _isLoading = true;
    });
    if (_user == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', _user!.id)
          .single();
      if (mounted) {
        setState(() {
          _userRole = data['role'];
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle error
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F4),
      appBar: _buildAppBar(context),
      body: Stack(
        children:
            _isLoading // Jika loading, tampilkan indicator di dalam List
            ? [
                const Center(
                  child: CircularProgressIndicator(color: Color(0xFF4D5D42)),
                ),
              ]
            : [
                // Jika tidak loading, tampilkan konten utama
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      100,
                    ), // Padding for nav bar
                    child: Column(
                      children: [
                        _buildSettingsList(),
                        const SizedBox(height: 32),
                        if (_user != null) _buildSellProductCard(context),
                        const SizedBox(height: 24),
                        _buildAuthSection(context),
                      ],
                    ),
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

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFFBF9F4),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF4A4A4A)),
        onPressed: () => context.go('/'), // Kembali ke home
      ),
      title: const Text(
        'Settings',
        style: TextStyle(
          color: Color(0xFF4D5D42),
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildSettingsList() {
    return Column(
      children: [
        if (_user != null)
          _buildSettingsItem(
            icon: Icons.person_outline,
            title: 'Edit Profil',
            route: '/edit-profile',
          ),
        _buildSettingsItem(
          icon: Icons.notifications_none_outlined,
          title: 'Notification',
        ),
        _buildSettingsItem(icon: Icons.help_outline, title: 'Help Center'),
        _buildSettingsItem(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
        ),
        _buildSettingsItem(icon: Icons.language_outlined, title: 'Language'),
        _buildSettingsItem(
          icon: Icons.dark_mode_outlined,
          title: 'Turn dark Theme',
          isSwitch: true,
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    bool isSwitch = false,
    String? route,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF4D5D42)),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, color: Color(0xFF4A4A4A)),
      ),
      trailing: isSwitch
          ? Switch(
              value: false,
              onChanged: (value) {},
              activeThumbColor: const Color(0xFF4D5D42),
            )
          : const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF4D5D42),
              size: 16,
            ),
      onTap: () {
        if (route != null) context.push(route);
      },
    );
  }

  Widget _buildSellProductCard(BuildContext context) {
    // Tentukan teks dan aksi berdasarkan peran pengguna
    if (_userRole == 'seller') {
      // Tampilan untuk Penjual
      return _buildRoleCard(
        context: context,
        text: 'Kelola Produk',
        icon: Icons.store_mall_directory_outlined,
        onTap: () {
          context.push('/manage-products');
        },
      );
    }

    // Tampilan untuk Pembeli (Buyer) yang ingin menjadi penjual
    return _buildRoleCard(
      context: context,
      text: 'Jual Produk Anda',
      icon: Icons.storefront_outlined,
      onTap: () => context.push('/seller-signup'),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final void Function() onTapAction = () {
      onTap();
    };

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTapAction,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF4D5D42), size: 28),
              const SizedBox(width: 16),
              Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF4D5D42),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthSection(BuildContext context) {
    if (_user != null) {
      return Column(
        children: [
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFFD9534F)),
            title: const Text(
              'Log Out',
              style: TextStyle(
                color: Color(0xFFD9534F),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) context.go('/login');
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Color(0xFFD9534F)),
            title: const Text(
              'Delete Account',
              style: TextStyle(
                color: Color(0xFFD9534F),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              //  delete account logic
            },
          ),
        ],
      );
    } else {
      return ListTile(
        leading: const Icon(Icons.login, color: Color(0xFF4D5D42)),
        title: const Text(
          'Log In',
          style: TextStyle(
            color: Color(0xFF4D5D42),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: () async {
          context.go('/login');
        },
      );
    }
  }
}
