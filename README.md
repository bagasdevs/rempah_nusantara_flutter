# 🌿 Rempah Nusantara

> Platform E-Commerce & Community Resep Rempah Nusantara

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 📱 Tentang Aplikasi

**Rempah Nusantara** adalah aplikasi mobile yang menggabungkan:
- 🛒 **E-Commerce** - Jual beli rempah-rempah tradisional Indonesia
- 📖 **Recipe Platform** - Berbagi dan mencari resep masakan dengan rempah
- 👥 **Community** - Koneksi antara petani, penjual, dan pembeli
- 🌱 **Educational** - Edukasi tentang rempah-rempah nusantara

---

## ✨ Fitur Utama

### 🛍️ E-Commerce
- Browse produk rempah dengan kategori
- Pencarian & filter produk
- Keranjang belanja & wishlist
- Checkout 3 langkah (Alamat → Pembayaran → Pengiriman)
- Tracking pesanan
- Review & rating produk

### 🍳 Recipe Platform
- Jelajah resep trending
- Detail resep lengkap (bahan, langkah, foto)
- Tambah resep sendiri (user-generated content)
- Favorit resep
- Filter berdasarkan kategori & tingkat kesulitan

### 👤 User Account
- Profil pengguna dengan statistik
- Manajemen alamat (CRUD)
- Riwayat pesanan
- Notifikasi real-time
- Pengaturan preferensi

### 🏪 Seller Features
- Pendaftaran sebagai penjual/petani
- Manajemen produk (tambah, edit, hapus)
- Dashboard penjualan
- Profil toko publik

---

## 🎨 Screenshots

```
[Home Screen]    [Product Detail]    [Recipe Detail]    [Cart]
```

---

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.0+
- Dart SDK 3.0+
- Android Studio / VS Code
- Android SDK / Xcode (untuk iOS)

### Installation

```bash
# Clone repository
git clone https://github.com/yourusername/rempah_nusantara_flutter.git

# Masuk ke direktori project
cd rempah_nusantara_flutter

# Install dependencies
flutter pub get

# Run aplikasi
flutter run
```

### Build untuk Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

### 🔧 APK Network Troubleshooting

**Masalah:** API berfungsi di browser tapi error di APK?

**Solusi cepat:**

1. **Gunakan helper script:**
   ```bash
   ./scripts/build_and_test.sh
   ```

2. **Manual build:**
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --release
   flutter install
   ```

3. **Monitor logs:**
   ```bash
   adb logcat | grep -E "(POST|GET|Error|Exception)"
   ```

4. **Test API dari HP:**
   Buka browser di HP: `https://api.bagas.website/api`

**Dokumentasi lengkap:**
- 📖 [Quick Fix Guide](docs/QUICK_FIX_APK.md)
- 📖 [Detailed Troubleshooting](docs/TROUBLESHOOTING_APK.md)

**Common issues:**
- ✅ Internet permission sudah ditambahkan
- ✅ Network security config sudah dikonfigurasi
- ⚠️ Pastikan SSL certificate server valid
- ⚠️ Pastikan HP terkoneksi internet

---

## 📂 Struktur Project

```
lib/
├── config/
│   └── app_theme.dart          # Design system (colors, typography, sizes)
├── screens/                     # 31 screen files
│   ├── home_screen.dart
│   ├── product_detail_screen.dart
│   ├── cart_screen.dart
│   ├── checkout_screen.dart
│   ├── add_recipe_screen.dart
│   └── ...
├── widgets/                     # Reusable widgets
│   ├── bottom_nav_bar.dart
│   ├── product_card.dart
│   └── ...
├── services/
│   └── api_service.dart        # API integration
├── app_router.dart             # Navigation routes
└── main.dart                   # Entry point

assets/
├── images/                     # Image assets
└── icons/                      # Icon assets
```

---

## 🎨 Design System

### Colors
- **Primary:** Green (`#4CAF50`) - Representing fresh herbs
- **Secondary:** Orange (`#FF9800`) - Warmth of spices
- **Error:** Red (`#F44336`)
- **Success:** Green (`#4CAF50`)

### Typography
- **Headings:** heading1, heading2, heading3, heading4
- **Body:** body1, body2, bodySmall, bodyMedium, bodyLarge
- **Special:** subtitle1, subtitle2, caption, button

### Spacing
- Consistent padding: small (8), medium (16), large (24), xlarge (32)
- Border radius: small (8), medium (12), large (16)

---

## 🔌 API Integration

### Base URL
```dart
static const String baseUrl = 'https://api.bagas.website';
```

**Note:** API sudah dikonfigurasi dengan HTTPS dan CORS support untuk mobile app.

### Endpoints (Ready for Integration)

```dart
// Authentication
POST   /api/auth/login
POST   /api/auth/register
POST   /api/auth/logout

// Products
GET    /api/products
GET    /api/products/:id
POST   /api/products
PUT    /api/products/:id
DELETE /api/products/:id

// Cart
GET    /api/cart
POST   /api/cart/add
PUT    /api/cart/update
DELETE /api/cart/remove

// Orders
GET    /api/orders
GET    /api/orders/:id
POST   /api/orders/create

// Recipes
GET    /api/recipes
GET    /api/recipes/:id
POST   /api/recipes
PUT    /api/recipes/:id

// User
GET    /api/users/profile
PUT    /api/users/profile
GET    /api/users/addresses
POST   /api/users/addresses
```

---

## 📱 Screens Overview

### Authentication (3 screens)
- Login
- Sign Up
- Complete Profile

### E-Commerce (5 screens)
- Home
- Categories
- Products List
- Product Detail
- Seller Profile

### Shopping Flow (4 screens)
- Search
- Cart
- Checkout (3 steps)
- Order Success

### User Account (6 screens)
- Profile
- Edit Profile
- Orders
- Favorites
- Address Management
- Notification

### Recipes (3 screens)
- Trending Recipes
- Recipe Detail
- Add Recipe

### Settings (4 screens)
- Settings
- Notification Settings
- Help Center
- Privacy Policy

### Seller (4 screens)
- Seller Signup
- Manage Products
- Edit Product
- Seller Dashboard

### Supporting (2 screens)
- Splash
- Onboarding

**Total: 31 Screens** ✅

---

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test

# Generate coverage report
flutter test --coverage
```

---

## 📦 Dependencies

### Core
```yaml
flutter_sdk: flutter
go_router: ^latest          # Navigation
```

### UI Components
```yaml
carousel_slider: ^latest    # Image carousel
```

### Media
```yaml
image_picker: ^latest       # Photo selection
```

### Utilities
```yaml
shared_preferences: ^latest # Local storage
http: ^latest               # HTTP requests
```

---

## 🎯 Roadmap

### ✅ Phase 1 - UI Development (COMPLETED)
- [x] All 31 screens implemented
- [x] Design system
- [x] Navigation flow
- [x] Mock data integration

### 🔄 Phase 2 - Backend Integration (IN PROGRESS)
- [ ] Real API endpoints
- [ ] Authentication flow
- [ ] Database integration
- [ ] Image upload service

### 📅 Phase 3 - Advanced Features (PLANNED)
- [ ] Payment gateway (Midtrans)
- [ ] Push notifications
- [ ] Real-time order tracking
- [ ] Chat/messaging
- [ ] Analytics
- [ ] Multi-language (i18n)

### 🚀 Phase 4 - Production (PLANNED)
- [ ] Performance optimization
- [ ] Testing (Unit, Widget, Integration)
- [ ] App Store submission
- [ ] Beta testing
- [ ] Production release

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👥 Team

- **Product Owner:** [Name]
- **Designer:** [Name]
- **Developer:** [Name]
- **Backend:** [Name]

---

## 📞 Support

- **Documentation:** [docs/](docs/)
- **API Docs:** https://api.bagas.website/api
- **Troubleshooting:** [docs/QUICK_FIX_APK.md](docs/QUICK_FIX_APK.md)

### 🐛 Debugging

Jika mengalami network error di APK:

1. Baca [Quick Fix Guide](docs/QUICK_FIX_APK.md)
2. Jalankan `./scripts/build_and_test.sh`
3. Monitor logs dengan `adb logcat`
4. Test API dari browser HP

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Indonesian spice farmers for inspiration
- Community contributors

---

## 📊 Project Status

```
UI Development:        ✅ 100% Complete (31/31 screens)
Backend Integration:   🔄 0% (Ready to start)
Testing:              📅 Planned
Documentation:        ✅ Complete
Code Quality:         ⭐⭐⭐⭐⭐ Excellent

Last Updated: 2024
Version: 1.0.0-dev
```

---

**Made with ❤️ for Indonesian Spice Farmers and Food Lovers**