import 'package:flutter/material.dart';
import 'package:rempah_nusantara/config/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Kebijakan Privasi',
          style: AppTextStyles.heading3.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSection(
              title: '1. Informasi yang Kami Kumpulkan',
              content:
                  'Kami mengumpulkan informasi yang Anda berikan secara langsung kepada kami, termasuk:\n\n'
                  '• Informasi akun: nama, email, nomor telepon, dan password\n'
                  '• Informasi profil: foto profil, preferensi masakan, tingkat keahlian\n'
                  '• Informasi transaksi: riwayat pembelian, metode pembayaran, alamat pengiriman\n'
                  '• Konten pengguna: resep, review, rating, dan komentar\n'
                  '• Informasi komunikasi: pesan dengan penjual atau customer service',
            ),
            _buildSection(
              title: '2. Penggunaan Informasi',
              content:
                  'Kami menggunakan informasi yang dikumpulkan untuk:\n\n'
                  '• Menyediakan, memelihara, dan meningkatkan layanan kami\n'
                  '• Memproses transaksi dan mengirimkan pesanan Anda\n'
                  '• Mengirimkan notifikasi terkait pesanan, promosi, dan update\n'
                  '• Memberikan rekomendasi produk dan resep yang dipersonalisasi\n'
                  '• Mencegah penipuan dan meningkatkan keamanan\n'
                  '• Menganalisis penggunaan aplikasi untuk peningkatan layanan\n'
                  '• Merespons pertanyaan dan memberikan dukungan pelanggan',
            ),
            _buildSection(
              title: '3. Berbagi Informasi',
              content:
                  'Kami tidak menjual informasi pribadi Anda. Kami dapat membagikan informasi Anda dengan:\n\n'
                  '• Penjual: informasi yang diperlukan untuk memproses pesanan\n'
                  '• Penyedia layanan: perusahaan yang membantu operasional kami (pembayaran, pengiriman, hosting)\n'
                  '• Kepatuhan hukum: jika diperlukan oleh hukum atau untuk melindungi hak kami\n'
                  '• Agregat data: data yang tidak dapat diidentifikasi untuk analisis',
            ),
            _buildSection(
              title: '4. Keamanan Data',
              content:
                  'Kami menerapkan langkah-langkah keamanan teknis dan organisasi untuk melindungi informasi Anda:\n\n'
                  '• Enkripsi data saat transmisi menggunakan SSL/TLS\n'
                  '• Penyimpanan password menggunakan algoritma hashing yang aman\n'
                  '• Akses terbatas ke data pribadi hanya untuk staf yang berwenang\n'
                  '• Pemantauan dan audit keamanan secara berkala\n'
                  '• Backup data reguler untuk mencegah kehilangan data',
            ),
            _buildSection(
              title: '5. Hak Pengguna',
              content:
                  'Anda memiliki hak untuk:\n\n'
                  '• Mengakses dan mendapatkan salinan data pribadi Anda\n'
                  '• Memperbarui atau memperbaiki informasi yang tidak akurat\n'
                  '• Menghapus akun dan data pribadi Anda\n'
                  '• Membatasi atau menolak pemrosesan data tertentu\n'
                  '• Menarik persetujuan kapan saja\n'
                  '• Mengajukan keluhan kepada otoritas perlindungan data\n\n'
                  'Untuk menggunakan hak-hak ini, hubungi kami melalui email: privacy@rempahnusantara.com',
            ),
            _buildSection(
              title: '6. Cookies dan Teknologi Pelacakan',
              content:
                  'Kami menggunakan cookies dan teknologi serupa untuk:\n\n'
                  '• Mengingat preferensi dan pengaturan Anda\n'
                  '• Memahami bagaimana Anda menggunakan aplikasi\n'
                  '• Meningkatkan pengalaman pengguna\n'
                  '• Menyediakan konten yang relevan\n\n'
                  'Anda dapat mengelola preferensi cookies melalui pengaturan perangkat Anda.',
            ),
            _buildSection(
              title: '7. Penyimpanan Data',
              content:
                  'Kami menyimpan informasi pribadi Anda selama:\n\n'
                  '• Akun Anda aktif\n'
                  '• Diperlukan untuk menyediakan layanan\n'
                  '• Diperlukan untuk mematuhi kewajiban hukum\n'
                  '• Diperlukan untuk menyelesaikan sengketa\n\n'
                  'Data transaksi disimpan selama periode yang diperlukan oleh peraturan perpajakan dan akuntansi.',
            ),
            _buildSection(
              title: '8. Layanan Pihak Ketiga',
              content:
                  'Aplikasi kami terintegrasi dengan layanan pihak ketiga:\n\n'
                  '• Gateway pembayaran (untuk memproses transaksi)\n'
                  '• Layanan pengiriman (untuk tracking pesanan)\n'
                  '• Analitik (untuk memahami penggunaan aplikasi)\n\n'
                  'Layanan pihak ketiga ini memiliki kebijakan privasi mereka sendiri. Kami mendorong Anda untuk membaca kebijakan mereka.',
            ),
            _buildSection(
              title: '9. Perlindungan Anak',
              content:
                  'Layanan kami tidak ditujukan untuk anak-anak di bawah 13 tahun. Kami tidak dengan sengaja mengumpulkan informasi pribadi dari anak-anak. '
                  'Jika Anda mengetahui bahwa anak Anda telah memberikan informasi pribadi kepada kami, silakan hubungi kami dan kami akan menghapusnya.',
            ),
            _buildSection(
              title: '10. Perubahan Kebijakan',
              content:
                  'Kami dapat memperbarui Kebijakan Privasi ini dari waktu ke waktu. Perubahan akan diumumkan melalui:\n\n'
                  '• Notifikasi dalam aplikasi\n'
                  '• Email ke alamat terdaftar\n'
                  '• Pembaruan pada halaman ini\n\n'
                  'Tanggal efektif perubahan akan dicantumkan di bagian atas kebijakan. Penggunaan berkelanjutan atas layanan kami setelah perubahan berarti Anda menerima kebijakan yang diperbarui.',
            ),
            _buildSection(
              title: '11. Hubungi Kami',
              content:
                  'Jika Anda memiliki pertanyaan tentang Kebijakan Privasi ini atau praktik privasi kami, silakan hubungi:\n\n'
                  '📧 Email: privacy@rempahnusantara.com\n'
                  '📱 WhatsApp: +62 812-3456-7890\n'
                  '📍 Alamat: Jl. Rempah Nusantara No. 123, Magelang, Indonesia\n\n'
                  'Kami akan merespons pertanyaan Anda dalam waktu 7 hari kerja.',
            ),
            const SizedBox(height: 24),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                  Icons.privacy_tip_outlined,
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
                      'Kebijakan Privasi',
                      style: AppTextStyles.heading3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Terakhir diperbarui: 15 Januari 2024',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Di Rempah Nusantara, kami berkomitmen untuk melindungi privasi Anda. '
            'Kebijakan ini menjelaskan bagaimana kami mengumpulkan, menggunakan, dan melindungi informasi pribadi Anda.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Kami menghormati privasi Anda dan berkomitmen untuk melindungi data pribadi Anda sesuai dengan peraturan perlindungan data yang berlaku.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
