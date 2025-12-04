# 🚀 Build Guide - Rempah Nusantara

Panduan lengkap untuk build aplikasi Rempah Nusantara dengan optimasi maksimal untuk performa loading yang cepat.

---

## 📋 Daftar Isi

1. [Persiapan](#persiapan)
2. [Build untuk Android](#build-untuk-android)
3. [Build untuk Web](#build-untuk-web)
4. [Optimasi yang Diterapkan](#optimasi-yang-diterapkan)
5. [Tips & Troubleshooting](#tips--troubleshooting)

---

## 🛠️ Persiapan

### Requirements

- Flutter SDK 3.9.0 atau lebih baru
- Dart SDK 3.9.0 atau lebih baru
- Android Studio (untuk build Android)
- Chrome/Edge (untuk test Web)

### Install Dependencies

```bash
flutter pub get
```

### Verify Setup

```bash
flutter doctor -v
```

---

## 📱 Build untuk Android

### 1. Development Build (Debug)

Untuk testing cepat dengan hot reload:

```bash
flutter run
```

### 2. Release Build (Optimized APK)

#### Metode A: Menggunakan Script Otomatis (Recommended)

```bash
./build_release.sh
```

Script ini akan:
- ✅ Clean previous builds
- ✅ Analyze code
- ✅ Build dengan semua optimasi
- ✅ Split APKs by ABI
- ✅ Show file sizes

#### Metode B: Manual Command

**Universal APK (Satu file untuk semua device):**

```bash
flutter build apk --release \
  --obfuscate \
  --split-debug-info=build/debug-info \
  --shrink \
  --tree-shake-icons
```

**Split APKs (APK terpisah per arsitektur - lebih kecil):**

```bash
flutter build apk --release \
  --split-per-abi \
  --obfuscate \
  --split-debug-info=build/debug-info \
  --shrink \
  --tree-shake-icons
```

### 3. Lokasi Output APK

Setelah build selesai, APK akan berada di:

```
build/app/outputs/flutter-apk/
├── app-release.apk                    # Universal APK (~50-80MB)
├── app-armeabi-v7a-release.apk       # 32-bit ARM (~25-35MB)
├── app-arm64-v8a-release.apk         # 64-bit ARM (~30-40MB)
└── app-x86_64-release.apk            # 64-bit x86 (~30-40MB)
```

### 4. Install APK ke Device

**Via USB:**

```bash
# Universal APK
flutter install

# Atau manual dengan adb
adb install build/app/outputs/flutter-apk/app-release.apk
```

**Via File Manager:**
1. Copy APK ke device
2. Buka File Manager
3. Tap APK file
4. Allow "Install from Unknown Sources"
5. Install

---

## 🌐 Build untuk Web

### 1. Development Build

```bash
flutter run -d chrome
```

### 2. Release Build (Optimized)

**HTML Renderer (Lebih kecil, kompatibel):**

```bash
flutter build web --release \
  --web-renderer html \
  --tree-shake-icons
```

**CanvasKit Renderer (Performa lebih baik):**

```bash
flutter build web --release \
  --web-renderer canvaskit \
  --tree-shake-icons
```

**Auto (Flutter pilih renderer terbaik):**

```bash
flutter build web --release \
  --web-renderer auto \
  --tree-shake-icons
```

### 3. Lokasi Output Web

```
build/web/
├── index.html
├── main.dart.js        # JavaScript bundle
├── assets/            # Assets (images, fonts, etc)
└── icons/             # App icons
```

### 4. Deploy Web

**Local Preview:**

```bash
cd build/web
python -m http.server 8000
# Buka http://localhost:8000
```

**Deploy ke Hosting:**

Upload semua file di `build/web/` ke:
- Firebase Hosting
- Netlify
- Vercel
- GitHub Pages
- Atau hosting lainnya

---

## ⚡ Optimasi yang Diterapkan

### 1. Image Optimization

#### Image Preloading
```dart
// Di main.dart - images di-preload saat splash screen
await ImageUtils.preloadImages(context);
```

**Benefit:**
- ✅ Images di-cache di memory
- ✅ Loading pertama lebih cepat
- ✅ No delay saat scroll
- ✅ Smooth user experience

#### Local Assets
```dart
// Semua placeholder diganti dengan local assets
ImageUtils.buildImage(
  imageUrl: imageUrl,
  productName: productName,
);
```

**Benefit:**
- ✅ No network dependency
- ✅ Offline-first
- ✅ Instant loading
- ✅ No external API calls

#### Image Caching
```dart
// Images di-cache untuk reuse
final cachedImage = ImageUtils.getCachedImage(assetPath);
```

### 2. Code Optimization

#### ProGuard (Android)
```kotlin
// build.gradle.kts
isMinifyEnabled = true
isShrinkResources = true
```

**Benefit:**
- ✅ Code size reduced ~40%
- ✅ Unused code removed
- ✅ Resources shrunk
- ✅ Faster startup

#### Code Obfuscation
```bash
flutter build apk --obfuscate
```

**Benefit:**
- ✅ Code protected
- ✅ Reverse engineering harder
- ✅ Smaller binary size

#### Tree Shaking
```bash
flutter build apk --tree-shake-icons
```

**Benefit:**
- ✅ Unused icons removed
- ✅ Font size reduced ~98%
- ✅ MaterialIcons: 1.6MB → 22KB
- ✅ CupertinoIcons: 257KB → 1.4KB

### 3. Build Optimization

#### Split APKs by ABI
```kotlin
splits {
    abi {
        isEnable = true
        include("armeabi-v7a", "arm64-v8a", "x86_64")
    }
}
```

**Benefit:**
- ✅ APK size ~50% smaller
- ✅ Faster download
- ✅ Less storage usage
- ✅ Faster installation

#### Split Debug Info
```bash
flutter build apk --split-debug-info=build/debug-info
```

**Benefit:**
- ✅ APK size smaller
- ✅ Debug symbols separate
- ✅ Can still debug crashes
- ✅ Upload to Firebase Crashlytics

### 4. Layout Optimization

#### Flexible Widgets
```dart
// ProductCard menggunakan Flexible bukan Expanded
Flexible(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [...]
  )
)
```

**Benefit:**
- ✅ No overflow errors
- ✅ Better responsive layout
- ✅ Efficient rendering
- ✅ Less rebuilds

#### Minimal Font Sizes
```dart
// Font size disesuaikan untuk mobile
fontSize: 11,  // Rating
fontSize: 13,  // Price
```

**Benefit:**
- ✅ More content visible
- ✅ No text overflow
- ✅ Better UX

---

## 📊 Performance Metrics

### APK Size Comparison

| Build Type | Size | Notes |
|-----------|------|-------|
| Debug APK | ~80-100MB | With debug symbols |
| Release APK (No optimization) | ~60-80MB | Basic release |
| Release APK (Optimized) | ~50-60MB | With ProGuard |
| Split APK (arm64-v8a) | ~30-40MB | 64-bit ARM only |
| Split APK (armeabi-v7a) | ~25-35MB | 32-bit ARM only |

### Web Bundle Size

| Renderer | Initial Load | Assets | Total |
|----------|--------------|--------|-------|
| HTML | ~2-3MB | ~650KB | ~3-4MB |
| CanvasKit | ~4-5MB | ~650KB | ~5-6MB |
| Auto | Variable | ~650KB | ~3-6MB |

### Loading Time

| Platform | Cold Start | Hot Start | Image Load |
|----------|------------|-----------|------------|
| Android (Debug) | ~3-5s | ~1-2s | ~200ms |
| Android (Release) | ~1-2s | ~500ms | ~50ms |
| Web (HTML) | ~2-3s | ~1s | ~100ms |
| Web (CanvasKit) | ~3-4s | ~1s | ~100ms |

---

## 💡 Tips & Troubleshooting

### Reduce APK Size Further

1. **Compress Images:**
   ```bash
   # Install imagemagick
   convert input.jpg -quality 85 -resize 1024x output.jpg
   ```

2. **Remove Unused Packages:**
   ```bash
   flutter pub deps
   # Remove unused dependencies from pubspec.yaml
   ```

3. **Enable R8 (Full mode):**
   ```properties
   # android/gradle.properties
   android.enableR8.fullMode=true
   ```

### Faster Build Times

1. **Use Gradle Daemon:**
   ```properties
   # android/gradle.properties
   org.gradle.daemon=true
   org.gradle.parallel=true
   org.gradle.configureondemand=true
   ```

2. **Increase Memory:**
   ```properties
   # android/gradle.properties
   org.gradle.jvmargs=-Xmx4g -XX:MaxPermSize=2048m
   ```

3. **Use Build Cache:**
   ```bash
   flutter build apk --build-cache
   ```

### Fix Common Errors

#### 1. "Out of Memory" Error

**Solution:**
```bash
# Increase Gradle heap size
export GRADLE_OPTS="-Xmx4g"
flutter build apk
```

#### 2. "ProGuard Rules" Error

**Solution:**
Check `android/app/proguard-rules.pro` exists and is properly configured.

#### 3. "Split APK" Error

**Solution:**
```kotlin
// android/app/build.gradle.kts
splits {
    abi {
        isEnable = true  // Pastikan true
        reset()
        include("armeabi-v7a", "arm64-v8a")
    }
}
```

#### 4. "Images Not Loading"

**Solution:**
```yaml
# pubspec.yaml - pastikan assets declared
flutter:
  assets:
    - assets/images/
```

#### 5. "Build Takes Too Long"

**Solution:**
```bash
# Clean dan rebuild
flutter clean
flutter pub get
flutter build apk --release
```

---

## 🎯 Best Practices

### 1. Version Control

Commit sebelum build:
```bash
git add .
git commit -m "Build v1.0.0"
git tag v1.0.0
```

### 2. Testing

Test sebelum release:
```bash
flutter test
flutter analyze
flutter build apk --release
```

### 3. Signing (Production)

Buat keystore untuk production:
```bash
keytool -genkey -v -keystore ~/release-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias rempah-nusantara
```

Configure `android/key.properties`:
```properties
storePassword=<password>
keyPassword=<password>
keyAlias=rempah-nusantara
storeFile=/path/to/release-keystore.jks
```

### 4. Monitoring

**Firebase Crashlytics:**
```bash
flutter pub add firebase_crashlytics
flutter pub add firebase_core
```

**Analytics:**
```bash
flutter pub add firebase_analytics
```

---

## 🚀 Quick Commands Reference

```bash
# Clean
flutter clean

# Get dependencies
flutter pub get

# Analyze code
flutter analyze

# Build debug APK
flutter build apk --debug

# Build release APK (optimized)
flutter build apk --release --obfuscate --split-debug-info=build/debug-info --shrink --tree-shake-icons

# Build split APKs
flutter build apk --release --split-per-abi

# Build Web
flutter build web --release --web-renderer html

# Install to device
flutter install

# Run release mode
flutter run --release
```

---

## 📞 Support

Jika ada masalah atau pertanyaan:

1. Check [Flutter Documentation](https://docs.flutter.dev)
2. Check [Android Documentation](https://developer.android.com)
3. Search [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)
4. Check project issues/discussions

---

## 📝 Changelog

### v1.0.0 (Current)
- ✅ Image preloading implemented
- ✅ ProGuard optimization
- ✅ Split APKs by ABI
- ✅ Tree shaking icons
- ✅ Local assets for all images
- ✅ Build script automation
- ✅ Comprehensive optimization

---

**Happy Building! 🎉**

*Rempah Nusantara - Bringing Indonesian Spices to Your Fingertips*