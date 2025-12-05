import 'package:flutter/material.dart';
import 'package:rempah_nusantara/config/app_theme.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final List<Map<String, String>> _faqs = [
    {
      'question': 'Bagaimana cara berbelanja?',
      'answer':
          'Pilih produk yang Anda inginkan, tambahkan ke keranjang, lalu lanjutkan ke checkout. Anda dapat memilih metode pembayaran dan alamat pengiriman di halaman checkout.',
    },
    {
      'question': 'Metode pembayaran apa saja yang tersedia?',
      'answer':
          'Kami menerima berbagai metode pembayaran termasuk COD (Cash on Delivery), Transfer Bank, dan E-Wallet seperti GoPay, OVO, dan Dana.',
    },
    {
      'question': 'Berapa lama waktu pengiriman?',
      'answer':
          'Waktu pengiriman tergantung metode yang dipilih:\n• Regular: 3-5 hari kerja\n• Express: 1-2 hari kerja\n• Same Day: Pengiriman di hari yang sama (untuk area tertentu)',
    },
    {
      'question': 'Bagaimana cara melacak pesanan?',
      'answer':
          'Anda dapat melacak pesanan melalui menu "Pesanan Saya" di profil. Nomor resi akan dikirimkan via email dan notifikasi aplikasi setelah pesanan dikirim.',
    },
    {
      'question': 'Apakah bisa mengembalikan produk?',
      'answer':
          'Ya, produk dapat dikembalikan dalam 7 hari setelah diterima jika terdapat kerusakan atau tidak sesuai. Hubungi customer service kami untuk proses pengembalian.',
    },
    {
      'question': 'Bagaimana cara menjadi penjual?',
      'answer':
          'Anda dapat mendaftar sebagai penjual melalui menu Settings > Kelola Produk. Lengkapi data toko dan unggah produk Anda untuk mulai berjualan.',
    },
    {
      'question': 'Apakah rempah dijamin kualitasnya?',
      'answer':
          'Semua rempah di platform kami melalui proses kurasi ketat. Kami bekerja sama dengan petani lokal terpercaya untuk memastikan kualitas dan keaslian produk.',
    },
    {
      'question': 'Bagaimana cara menggunakan voucher?',
      'answer':
          'Masukkan kode voucher di halaman keranjang belanja sebelum checkout. Diskon akan otomatis teraplikasi pada total belanja Anda.',
    },
    {
      'question': 'Apakah ada minimum pembelian?',
      'answer':
          'Tidak ada minimum pembelian. Namun, beberapa voucher atau promo mungkin memerlukan minimum pembelian tertentu.',
    },
    {
      'question': 'Bagaimana cara menghubungi penjual?',
      'answer':
          'Anda dapat menghubungi penjual melalui tombol "Chat" di halaman detail produk atau melalui halaman profil penjual.',
    },
  ];

  String _searchQuery = '';
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = _faqs
        .asMap()
        .entries
        .where(
          (entry) =>
              entry.value['question']!.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              entry.value['answer']!.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
        )
        .toList();

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
          'Pusat Bantuan',
          style: AppTextStyles.heading3.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContactSection(),
                  const SizedBox(height: 24),
                  Text(
                    'Pertanyaan Umum (FAQ)',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (filteredFaqs.isEmpty)
                    _buildEmptyState()
                  else
                    ..._buildFaqList(filteredFaqs),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _expandedIndex = null;
          });
        },
        decoration: InputDecoration(
          hintText: 'Cari pertanyaan...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                ),
                child: const Icon(
                  Icons.headset_mic_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Butuh Bantuan?',
                      style: AppTextStyles.heading3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Tim kami siap membantu Anda',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildContactButton(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  onTap: () {
                    _showContactDialog(
                      'Email Support',
                      'support@rempahnusantara.com',
                      Icons.email_outlined,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildContactButton(
                  icon: Icons.phone_outlined,
                  label: 'Telepon',
                  onTap: () {
                    _showContactDialog(
                      'Telepon Support',
                      '+62 812-3456-7890\nSenin - Jumat: 08:00 - 17:00',
                      Icons.phone_outlined,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildContactButton(
                  icon: Icons.chat_outlined,
                  label: 'Live Chat',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fitur Live Chat dalam pengembangan'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildContactButton(
                  icon: Icons.help_outline,
                  label: 'WhatsApp',
                  onTap: () {
                    _showContactDialog(
                      'WhatsApp Support',
                      '+62 812-3456-7890\nKlik untuk membuka WhatsApp',
                      Icons.help_outline,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFaqList(List<MapEntry<int, Map<String, String>>> faqs) {
    return faqs.map((entry) {
      final index = entry.key;
      final faq = entry.value;
      final isExpanded = _expandedIndex == index;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          border: Border.all(
            color: isExpanded ? AppColors.primary : AppColors.border,
            width: isExpanded ? 2 : 1,
          ),
          boxShadow: [
            if (isExpanded)
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: InkWell(
          onTap: () {
            setState(() {
              _expandedIndex = isExpanded ? null : index;
            });
          },
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        faq['question']!,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isExpanded
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: isExpanded
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    ),
                    child: Text(
                      faq['answer']!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada hasil',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba kata kunci lain atau hubungi customer service',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showContactDialog(String title, String info, IconData icon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          info,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            height: 1.5,
          ),
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
}
