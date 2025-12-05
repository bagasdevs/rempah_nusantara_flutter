# 🌿 Rempah Nusantara

> Platform E-Commerce & Community Rempah Nusantara

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 📱 Tentang Aplikasi

**Rempah Nusantara** adalah aplikasi mobile marketplace yang menghubungkan petani rempah dengan pembeli, menyediakan platform jual-beli rempah tradisional Indonesia dengan fitur edukasi dan komunitas.

---

## ✨ Fitur Utama

### 🛍️ E-Commerce
- Browse & pencarian produk rempah
- Keranjang belanja & wishlist
- Checkout dengan integrasi Midtrans
- Tracking pesanan real-time dengan auto-polling
- Review & rating produk

### 👤 User Features
- Manajemen profil & alamat
- Riwayat pesanan dengan filter status
- Notifikasi real-time

### 🏪 Seller Features
- Pendaftaran penjual/petani
- Manajemen produk (CRUD)
- Dashboard penjualan

---

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.0+
- Dart SDK 3.0+

### Installation

```bash
# Clone repository
git clone https://github.com/yourusername/rempah_nusantara_flutter.git

# Install dependencies
cd rempah_nusantara_flutter
flutter pub get

# Run aplikasi
flutter run
```

### Environment Setup

Buat file `.env` di root project:
```
API_BASE_URL=https://your-api-url.com
MIDTRANS_CLIENT_KEY=your_client_key
MIDTRANS_MERCHANT_ID=your_merchant_id
```

---

## 📂 Struktur Project

```
lib/
├── config/
│   └── app_theme.dart          # Design system
├── screens/                     # 29 screens
│   ├── home_screen.dart
│   ├── product_detail_screen.dart
│   ├── cart_screen.dart
│   ├── checkout_screen.dart
│   ├── order_status_screen.dart
│   └── ...
├── widgets/                     # Reusable components
├── services/
│   ├── api_service.dart        # REST API
│   ├── auth_service.dart       # Authentication
│   └── payment_service.dart    # Midtrans payment
├── app_router.dart             # GoRouter navigation
└── main.dart
```

---

## 🔌 API Endpoints

```dart
// Authentication
POST   /api/auth/login
POST   /api/auth/register

// Products
GET    /api/products
GET    /api/products/:id
POST   /api/products

// Cart & Orders
GET    /api/cart
POST   /api/cart/add
GET    /api/orders
POST   /api/orders/create

// Addresses
GET    /api/addresses
POST   /api/addresses

// Payments
POST   /api/payments/create-transaction
POST   /api/payments/webhook
```

---

## 💳 Payment Integration

Integrasi dengan Midtrans:
- ✅ Android/iOS: Native SDK
- ✅ Web: Redirect flow
- ✅ Auto-polling status pembayaran
- ✅ Webhook support

---

## 📦 Dependencies

### Core
- `go_router` - Navigation
- `http` - HTTP requests
- `shared_preferences` - Local storage

### UI & Media
- `carousel_slider` - Image carousel
- `image_picker` - Photo selection
- `url_launcher` - Open URLs

### Payment
- `midtrans_sdk` - Payment gateway

---

## 🎯 Progress & Roadmap

### ✅ Phase 1 - UI Development (100%)
- [x] 29 screens implemented
- [x] Design system & theming
- [x] Navigation dengan GoRouter

### ✅ Phase 2 - Core Integration (90%)
- [x] REST API integration
- [x] Authentication (JWT)
- [x] Cart & checkout
- [x] Payment integration (Midtrans)
- [x] Order tracking dengan auto-polling
- [x] Address management

### 🔄 Phase 3 - Backend & Polish (In Progress - 80%)
- [x] Core API endpoints
- [x] Payment webhook
- [ ] Image upload service
- [ ] Search optimization
- [ ] Seller analytics

### 📅 Phase 4 - Advanced Features (Planned)
- [ ] Push notifications (FCM)
- [ ] Real-time chat
- [ ] Product recommendations
- [ ] Multi-language (i18n)
- [ ] Dark mode
- [ ] Offline mode

### 🚀 Phase 5 - Production (Planned)
- [ ] Performance optimization
- [ ] Complete testing
- [ ] Security audit
- [ ] Beta testing
- [ ] Production deployment

---

## 📊 Project Status

```
UI Development:          ✅ 100% (29/29 screens)
API Integration:         ✅ 90%
Backend Development:     🔄 80%
Testing:                 📅 Planned
Production Ready:        🔄 In Progress

Last Updated: January 2025
Version: 1.0.0-beta
```

---

## 🛠️ Development

### Code Quality
```bash
flutter format .      # Format code
flutter analyze       # Analyze code
flutter test          # Run tests
```

### Build
```bash
flutter build apk --release           # Android APK
flutter build appbundle --release     # Android Bundle
flutter build ios --release           # iOS
```

---

## 🔒 Security Best Practices

- ✅ Environment variables untuk credentials
- ✅ HTTPS untuk API calls
- ✅ JWT authentication
- ✅ Input validation
- ❌ Never commit `.env` atau API keys

---

## 🐛 Common Issues

**Price type error:** ✅ Fixed - Semua field price sudah di-parse dengan benar

**Payment SDK di web:** ✅ Fixed - Menggunakan redirect flow

**Route not found:** Check `app_router.dart` untuk route definitions

---

## 📄 License

MIT License - see [LICENSE](LICENSE) file

---

## 🙏 Acknowledgments

- Flutter team
- Indonesian spice farmers
- Midtrans payment gateway
- Open source community

---

**Made with ❤️ for Indonesian Spice Farmers**

🌿 Supporting local farmers • Preserving traditions • Building community