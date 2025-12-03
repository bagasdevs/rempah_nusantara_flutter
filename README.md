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
- Checkout multi-langkah (Alamat → Pembayaran → Konfirmasi)
- Integrasi pembayaran dengan Midtrans
- Tracking pesanan real-time dengan auto-polling
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
- Riwayat pesanan dengan filter status
- Notifikasi real-time
- Pengaturan preferensi

### 🏪 Seller Features
- Pendaftaran sebagai penjual/petani
- Manajemen produk (tambah, edit, hapus)
- Dashboard penjualan
- Profil toko publik

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

### Environment Setup

1. Buat file `.env` di root project (tidak di-commit ke Git):
```
API_BASE_URL=https://your-api-url.com
MIDTRANS_CLIENT_KEY=your_client_key
MIDTRANS_MERCHANT_ID=your_merchant_id
```

2. Konfigurasi `api_service.dart`:
```dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);
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

---

## 📂 Struktur Project

```
lib/
├── config/
│   └── app_theme.dart          # Design system (colors, typography, sizes)
├── screens/                     # 31+ screen files
│   ├── home_screen.dart
│   ├── product_detail_screen.dart
│   ├── cart_screen.dart
│   ├── checkout_screen.dart
│   ├── order_status_screen.dart
│   ├── orders_screen.dart
│   ├── add_recipe_screen.dart
│   └── ...
├── widgets/                     # Reusable widgets
│   ├── bottom_nav_bar.dart
│   ├── product_card.dart
│   └── ...
├── services/
│   ├── api_service.dart        # REST API integration
│   ├── auth_service.dart       # Authentication
│   └── payment_service.dart    # Payment (Midtrans)
├── app_router.dart             # Navigation routes (GoRouter)
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

### Configuration

API endpoint dikonfigurasi melalui environment variables untuk keamanan:

```dart
// services/api_service.dart
class ApiService {
  static const String baseUrl = String.fromEnvironment('API_BASE_URL');
  
  // Header dengan JWT token
  static Map<String, String> _getHeaders({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
```

### Endpoints Structure

```dart
// Authentication
POST   /api/auth/login
POST   /api/auth/register
POST   /api/auth/logout
GET    /api/auth/user

// Products
GET    /api/products
GET    /api/products/:id
POST   /api/products
PUT    /api/products/:id
DELETE /api/products/:id

// Cart
GET    /api/cart
POST   /api/cart/add
PUT    /api/cart/update/:id
DELETE /api/cart/remove/:id

// Orders
GET    /api/orders
GET    /api/orders/detail?id=:id
POST   /api/orders/create

// Addresses
GET    /api/addresses
POST   /api/addresses
PUT    /api/addresses/:id
DELETE /api/addresses/:id

// Payments (Midtrans)
POST   /api/payments/create-transaction
POST   /api/payments/webhook

// Recipes
GET    /api/recipes
GET    /api/recipes/:id
POST   /api/recipes
PUT    /api/recipes/:id

// User
GET    /api/users/profile
PUT    /api/users/profile
```

### Error Handling

```dart
try {
  final response = await http.get(url, headers: headers);
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to load data');
  }
} catch (e) {
  print('Error: $e');
  rethrow;
}
```

---

## 💳 Payment Integration

### Midtrans Setup

Aplikasi terintegrasi dengan Midtrans untuk payment gateway:

**Platform Support:**
- ✅ Android/iOS: Native SDK (`midtrans_sdk` plugin)
- ✅ Web: Redirect flow (`url_launcher`)

**Payment Flow:**
1. User melakukan checkout
2. Backend create payment transaction
3. Dapat `snap_token` dan `redirect_url`
4. Mobile: Buka Midtrans SDK
5. Web: Buka redirect URL di tab baru
6. Auto-polling untuk update status payment

**Key Features:**
- Snap popup untuk Android/iOS
- Redirect flow untuk Web
- Auto-refresh order status
- Webhook support untuk real-time update

---

## 🔄 State Management

### Current Implementation
- Local state dengan `StatefulWidget`
- `SharedPreferences` untuk persistence
- JWT token storage untuk auth

### Planned Improvements
- Provider / Riverpod untuk global state
- Better cache management
- Offline mode support

---

## 📱 Screens Overview

### Authentication (3 screens)
- Login
- Sign Up  
- Complete Profile

### E-Commerce (6 screens)
- Home
- Categories
- Products List
- Product Detail
- Seller Profile
- Search

### Shopping Flow (5 screens)
- Cart
- Checkout (multi-step)
- Order Success
- Order Status (with auto-polling)
- Orders (with filter tabs)

### User Account (6 screens)
- Profile
- Edit Profile
- Address Management (CRUD)
- Favorites
- Notification
- Settings

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

**Total: 33 Screens** ✅

---

## 🛠️ Development Guidelines

### Code Style
```bash
# Format code
flutter format .

# Analyze code
flutter analyze

# Check for issues
flutter pub run dart_code_metrics:metrics analyze lib
```

### Git Workflow
```bash
# Feature branch
git checkout -b feature/new-feature

# Commit dengan conventional commits
git commit -m "feat: add payment status polling"
git commit -m "fix: resolve cart price type error"
git commit -m "docs: update README"

# Push & create PR
git push origin feature/new-feature
```

### Security Best Practices
- ❌ Jangan commit API keys, tokens, atau credentials
- ✅ Gunakan environment variables
- ✅ Tambahkan `.env` ke `.gitignore`
- ✅ Gunakan HTTPS untuk semua API calls
- ✅ Validate dan sanitize user input
- ✅ Implement proper error handling

---

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/widget_test.dart

# Integration tests
flutter test integration_test
```

### Test Coverage Goals
- Unit Tests: 80%+
- Widget Tests: 70%+
- Integration Tests: Key flows

---

## 📦 Dependencies

### Core
```yaml
flutter_sdk: flutter
go_router: ^13.0.0         # Navigation & routing
```

### UI Components
```yaml
carousel_slider: ^4.2.1    # Image carousel
```

### Media & Files
```yaml
image_picker: ^1.0.7       # Photo selection
url_launcher: ^6.2.4       # Open URLs (for web payment)
```

### Storage & Network
```yaml
shared_preferences: ^2.2.2 # Local storage
http: ^1.2.0               # HTTP requests
```

### Payment
```yaml
midtrans_sdk: ^0.2.0       # Midtrans integration (Android/iOS)
```

### Development
```yaml
flutter_launcher_icons: ^latest  # App icons
flutter_native_splash: ^latest   # Splash screen
```

---

## 🎯 Roadmap

### ✅ Phase 1 - UI Development (COMPLETED)
- [x] All 33 screens implemented
- [x] Design system & theming
- [x] Navigation flow with GoRouter
- [x] Page transitions & animations
- [x] Mock data integration

### ✅ Phase 2 - Core Integration (COMPLETED)
- [x] REST API integration
- [x] Authentication flow (JWT)
- [x] Cart & checkout flow
- [x] Payment integration (Midtrans)
- [x] Order status tracking
- [x] Address management
- [x] Auto-polling for order updates

### 🔄 Phase 3 - Backend Completion (IN PROGRESS)
- [ ] Complete all API endpoints
- [ ] Implement webhook handling
- [ ] Image upload service
- [ ] Recipe API integration
- [ ] Search & filter optimization
- [ ] Timezone handling (Asia/Jakarta)

### 📅 Phase 4 - Advanced Features (PLANNED)
- [ ] Push notifications (FCM)
- [ ] Real-time chat/messaging
- [ ] Advanced analytics
- [ ] Product recommendations
- [ ] Multi-language support (i18n)
- [ ] Dark mode
- [ ] Offline mode & sync

### 🚀 Phase 5 - Production (PLANNED)
- [ ] Performance optimization
- [ ] Complete test coverage
- [ ] Security audit
- [ ] App Store optimization
- [ ] Beta testing program
- [ ] Production deployment
- [ ] Monitoring & logging setup

---

## 🐛 Troubleshooting

### Common Issues

**Problem: Price type error**
```
TypeError: type 'String' is not a subtype of type 'num?'
```
**Solution:** ✅ Fixed - All price fields now properly parse strings to numbers

**Problem: Route not found**
```
GoException: no routes for location: /path
```
**Solution:** Check `app_router.dart` for route definitions

**Problem: Payment SDK error on web**
```
MissingPluginException: No implementation found for method init
```
**Solution:** ✅ Fixed - Web uses redirect flow instead of SDK

**Problem: Network permission denied (Android)**
**Solution:** Add internet permission to `AndroidManifest.xml`
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

---

## 📊 Project Status

```
UI Development:          ✅ 100% Complete (33/33 screens)
API Integration:         ✅ 85% Complete
  - Auth:                ✅ Done
  - Products:            ✅ Done
  - Cart:                ✅ Done
  - Checkout:            ✅ Done
  - Payment:             ✅ Done
  - Orders:              ✅ Done
  - Addresses:           ✅ Done
  - Recipes:             🔄 In Progress
Backend Requirements:    🔄 85% Complete
Testing:                 📅 Planned
Documentation:           ✅ Complete
Code Quality:            ⭐⭐⭐⭐⭐ Excellent (No errors/warnings)

Last Updated: January 2024
Version: 1.0.0-beta
```

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'feat: add some amazing feature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Contribution Guidelines
- Follow Flutter style guide
- Write meaningful commit messages
- Add tests for new features
- Update documentation
- Ensure no diagnostic errors/warnings

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📞 Support & Documentation

### Development Setup
1. Clone repository
2. Copy `.env.example` to `.env`
3. Configure environment variables
4. Run `flutter pub get`
5. Run `flutter run`

### Getting Help
- Check existing issues on GitHub
- Read inline code documentation
- Review API integration examples in `services/` folder

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Indonesian spice farmers for inspiration
- Midtrans for payment gateway
- Community contributors
- Open source packages used in this project

---

## 📝 Notes for Developers

### Backend Requirements

**Priority Endpoints to Implement:**
1. ✅ `GET /api/orders` - List orders with filters
2. ✅ `GET /api/orders/detail` - Order detail
3. 🔄 `POST /api/payments/webhook` - Midtrans webhook handler
4. 🔄 Recipe endpoints (CRUD)
5. 🔄 Search & filter optimization

**Important:**
- Set timezone to `Asia/Jakarta` on backend
- Ensure all numeric fields return as numbers (not strings)
- Implement proper CORS headers
- Use HTTPS with valid SSL certificate
- Handle file uploads for products/recipes

### Security Checklist
- [ ] Never commit `.env` file
- [ ] Never hardcode API keys or tokens
- [ ] Validate all user inputs
- [ ] Sanitize data before display
- [ ] Use HTTPS only
- [ ] Implement rate limiting on backend
- [ ] Add proper authentication & authorization
- [ ] Regular security audits

---

**Made with ❤️ for Indonesian Spice Farmers and Food Lovers**

🌿 Supporting local farmers • Preserving traditional recipes • Building community