# 🌿 Rempah Nusantara

> Platform E-Commerce Rempah Tradisional Indonesia

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)](https://dart.dev)

---

## 📱 Tentang

Marketplace yang menghubungkan petani rempah dengan pembeli, dengan fitur AI untuk prediksi harga dan deteksi anomali.

## ✨ Fitur

| Modul | Fitur |
|-------|-------|
| **Buyer** | Browse produk, keranjang, checkout, payment (Midtrans), tracking pesanan, review |
| **Seller** | Registrasi penjual, CRUD produk, dashboard penjualan, kelola pesanan |
| **Admin** | Dashboard analytics, kelola users/products/orders, moderasi |
| **AI** | Prediksi harga (LSTM), sentiment analysis (CNN-LSTM), deteksi tengkulak (Isolation Forest) |

## 🚀 Quick Start

```bash
git clone https://github.com/yourusername/rempah_nusantara_flutter.git
cd rempah_nusantara_flutter
flutter pub get
flutter run
```

## 📂 Struktur

```
lib/
├── config/          # Theme & constants
├── screens/         # 33 screens (termasuk admin/)
├── widgets/         # Reusable components
├── services/        # API, AI, Preferences, Notifications
├── app_router.dart  # GoRouter navigation
└── main.dart
```

## 🔌 API Endpoints

| Kategori | Endpoints |
|----------|-----------|
| Auth | `/api/auth/login`, `/signup`, `/logout` |
| Products | `/api/products` (CRUD) |
| Cart/Orders | `/api/cart`, `/api/orders` |
| Payments | `/api/payments/create-transaction` |
| Seller | `/api/seller/register`, `/dashboard`, `/orders` |
| Admin | `/api/admin/dashboard`, `/users`, `/products`, `/orders` |
| AI | `/api/ai/price`, `/sentiment`, `/anomaly` |

## 📊 Status

| Component | Progress |
|-----------|----------|
| UI (33 screens) | ✅ 100% |
| Buyer Features | ✅ 100% |
| Seller Features | ✅ 100% |
| Admin Panel | ✅ 100% |
| Payment (Midtrans) | ✅ 100% |
| AI Integration | ⚠️ 80% (perlu deploy FastAPI) |
| Push Notifications | ⚠️ 70% (perlu config Firebase) |

## 📦 Dependencies

- `go_router` - Navigation
- `http` - API calls
- `shared_preferences` - Local storage
- `midtrans_sdk` - Payment
- `firebase_messaging` - Push notifications
- `image_picker`, `carousel_slider` - UI

## 🛠️ Build

```bash
flutter build apk --release      # Android
flutter build ios --release      # iOS
```

## 🔒 Security

- ✅ JWT Authentication
- ✅ HTTPS API calls
- ✅ Input validation
- ❌ Never commit `.env` atau API keys

---

**Version:** 1.1.0-beta | **Last Updated:** January 2025

🌿 *Made with ❤️ for Indonesian Spice Farmers*