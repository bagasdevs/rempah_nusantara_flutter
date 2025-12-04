import 'package:flutter/material.dart';
import 'package:myapp/config/app_theme.dart';

/// Utility class for handling image loading with local asset fallbacks
class ImageUtils {
  // Private constructor to prevent instantiation
  ImageUtils._();

  // Cache for preloaded images
  static final Map<String, ImageProvider> _imageCache = {};
  static bool _isPreloaded = false;

  /// Maps product names to local asset paths
  static String? _getAssetPathFromProductName(String productName) {
    final nameLower = productName.toLowerCase();

    // Map product names to local assets
    if (nameLower.contains('kunyit') || nameLower.contains('turmeric')) {
      return 'assets/images/turmeric.jpg';
    } else if (nameLower.contains('kayu manis') ||
        nameLower.contains('cinnamon') ||
        nameLower.contains('cinammon')) {
      return 'assets/images/cinammon.jpg';
    } else if (nameLower.contains('cengkeh') || nameLower.contains('clove')) {
      return 'assets/images/cloves.jpg';
    } else if (nameLower.contains('pala') || nameLower.contains('nutmeg')) {
      return 'assets/images/nutmeg.jpg';
    } else if (nameLower.contains('lada') ||
        nameLower.contains('merica') ||
        nameLower.contains('pepper')) {
      return 'assets/images/pepper.jpg';
    } else if (nameLower.contains('jintan') || nameLower.contains('cumin')) {
      return 'assets/images/cumin.jpg';
    }

    return null;
  }

  /// Returns a default fallback asset image
  static String getDefaultAsset() {
    return 'assets/images/turmeric.jpg';
  }

  /// Builds an image widget with smart fallback logic
  /// Priority: local asset (by name) -> network URL -> default asset -> icon
  static Widget buildImage({
    required String? imageUrl,
    required String productName,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    // Try to get asset path from product name first
    final assetPath = _getAssetPathFromProductName(productName);

    Widget imageWidget;

    if (assetPath != null) {
      // Use local asset if available (with cache if preloaded)
      final cachedImage = getCachedImage(assetPath);
      imageWidget = Image(
        image: cachedImage ?? AssetImage(assetPath),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackIcon(width, height);
        },
      );
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      // Check if URL is actually a local asset path
      if (!imageUrl.startsWith('http')) {
        final cachedImage = getCachedImage(imageUrl);
        imageWidget = Image(
          image: cachedImage ?? AssetImage(imageUrl),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return _buildImageWithAssetFallback(
              imageUrl: getDefaultAsset(),
              isAsset: true,
              width: width,
              height: height,
              fit: fit,
            );
          },
        );
      } else {
        // Use network image with asset fallback
        imageWidget = _buildImageWithAssetFallback(
          imageUrl: imageUrl,
          isAsset: false,
          width: width,
          height: height,
          fit: fit,
        );
      }
    } else {
      // No URL provided, use default asset
      final defaultAsset = getDefaultAsset();
      final cachedImage = getCachedImage(defaultAsset);
      imageWidget = Image(
        image: cachedImage ?? AssetImage(defaultAsset),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackIcon(width, height);
        },
      );
    }

    // Wrap with border radius if provided
    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius, child: imageWidget);
    }

    return imageWidget;
  }

  /// Builds a network image with asset fallback
  static Widget _buildImageWithAssetFallback({
    required String imageUrl,
    required bool isAsset,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (isAsset) {
      final cachedImage = getCachedImage(imageUrl);
      return Image(
        image: cachedImage ?? AssetImage(imageUrl),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackIcon(width, height);
        },
      );
    }

    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // Try to load default asset on network error
        final defaultAsset = getDefaultAsset();
        final cachedImage = getCachedImage(defaultAsset);
        return Image(
          image: cachedImage ?? AssetImage(defaultAsset),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackIcon(width, height);
          },
        );
      },
    );
  }

  /// Builds a fallback icon when all image loading fails
  static Widget _buildFallbackIcon(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: AppColors.background,
      child: const Icon(
        Icons.local_florist,
        size: 50,
        color: AppColors.iconGrey,
      ),
    );
  }

  /// Builds an image for product cards
  static Widget buildProductCardImage({
    required String? imageUrl,
    required String productName,
    double height = 140,
  }) {
    return Container(
      height: height,
      width: double.infinity,
      color: AppColors.background,
      child: buildImage(
        imageUrl: imageUrl,
        productName: productName,
        height: height,
        fit: BoxFit.cover,
      ),
    );
  }

  /// Builds an image for product detail carousel
  static Widget buildCarouselImage({
    required String? imageUrl,
    required String productName,
    required double width,
    double height = 300,
  }) {
    return Container(
      width: width,
      height: height,
      color: Colors.white,
      child: buildImage(
        imageUrl: imageUrl,
        productName: productName,
        width: width,
        height: height,
        fit: BoxFit.cover,
      ),
    );
  }

  /// Checks if a URL is a placeholder URL
  static bool isPlaceholderUrl(String? url) {
    if (url == null || url.isEmpty) return true;
    return url.contains('placeholder') || url.contains('via.placeholder.com');
  }

  /// Replaces placeholder URLs with asset paths based on product name
  static String? replaceUrlWithAsset(String? url, String productName) {
    if (isPlaceholderUrl(url)) {
      return _getAssetPathFromProductName(productName) ?? getDefaultAsset();
    }
    return url;
  }

  /// Preload all local assets for faster loading
  /// Call this in main() or splash screen
  static Future<void> preloadImages(BuildContext context) async {
    if (_isPreloaded) return;

    final assets = [
      'assets/images/turmeric.jpg',
      'assets/images/cinammon.jpg',
      'assets/images/cloves.jpg',
      'assets/images/nutmeg.jpg',
      'assets/images/pepper.jpg',
      'assets/images/cumin.jpg',
      'assets/images/Logo_Rempah_Nusantara.png',
    ];

    try {
      // Preload each image individually with error handling
      for (final asset in assets) {
        try {
          final imageProvider = AssetImage(asset);
          _imageCache[asset] = imageProvider;
          await precacheImage(imageProvider, context).timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint('Timeout preloading: $asset');
            },
          );
        } catch (e) {
          debugPrint('Error preloading $asset: $e');
          // Continue with other images even if one fails
        }
      }
      _isPreloaded = true;
    } catch (e) {
      debugPrint('Error preloading images: $e');
      _isPreloaded = true; // Mark as preloaded anyway to not block app
    }
  }

  /// Get cached image provider if available
  static ImageProvider? getCachedImage(String assetPath) {
    return _imageCache[assetPath];
  }

  /// Check if images are preloaded
  static bool get isPreloaded => _isPreloaded;
}
