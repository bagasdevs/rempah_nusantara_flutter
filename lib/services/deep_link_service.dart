import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';

/// Service to handle incoming deep links (app links) from external sources
/// Primary use case: Midtrans payment callback
class DeepLinkService {
  static DeepLinkService? _instance;
  static DeepLinkService get instance => _instance ??= DeepLinkService._();

  DeepLinkService._();

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  /// Callback function to handle parsed deep link paths
  /// This will be called with the path to navigate to (e.g., '/order-status/123')
  Function(String path)? onLinkReceived;

  /// Initialize the deep link service
  /// Should be called once during app startup
  Future<void> init() async {
    if (kIsWeb) {
      // Web doesn't use app_links in the same way
      print('🔗 [DeepLinkService] Web platform - skipping app_links init');
      return;
    }

    try {
      _appLinks = AppLinks();

      // Handle initial link if app was launched from a deep link
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        print('🔗 [DeepLinkService] Initial link received: $initialUri');
        _handleIncomingLink(initialUri);
      }

      // Listen for subsequent deep links while app is running
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (Uri uri) {
          print('🔗 [DeepLinkService] Link stream received: $uri');
          _handleIncomingLink(uri);
        },
        onError: (error) {
          print('❌ [DeepLinkService] Link stream error: $error');
        },
      );

      print('✅ [DeepLinkService] Initialized successfully');
    } catch (e) {
      print('❌ [DeepLinkService] Failed to initialize: $e');
    }
  }

  /// Handle incoming deep link URI
  void _handleIncomingLink(Uri uri) {
    print('🔗 [DeepLinkService] Processing URI: $uri');
    print('🔗 [DeepLinkService] Scheme: ${uri.scheme}');
    print('🔗 [DeepLinkService] Host: ${uri.host}');
    print('🔗 [DeepLinkService] Path: ${uri.path}');
    print('🔗 [DeepLinkService] Query: ${uri.queryParameters}');

    // Handle Midtrans payment callback
    // Expected format: com.rempahnusantara://payment/callback?order_id=TRX-{orderId}-{timestamp}
    if (uri.scheme == 'com.rempahnusantara' && uri.host == 'payment') {
      _handlePaymentCallback(uri);
      return;
    }

    // Handle other custom schemes if needed
    if (uri.scheme == 'com.rempahnusantara') {
      // Generic handler for other deep links
      final path = '/${uri.host}${uri.path}';
      _navigateTo(path);
      return;
    }

    print('⚠️ [DeepLinkService] Unhandled URI scheme: ${uri.scheme}');
  }

  /// Handle Midtrans payment callback specifically
  void _handlePaymentCallback(Uri uri) {
    print('💳 [DeepLinkService] Processing payment callback');

    // Get order_id from query parameters
    // Midtrans sends back the transaction_id we provided (format: TRX-{orderId}-{timestamp})
    final transactionId = uri.queryParameters['order_id'];
    final appOrderId =
        uri.queryParameters['app_order_id']; // Direct order ID we added
    final transactionStatus = uri.queryParameters['transaction_status'];
    final statusCode = uri.queryParameters['status_code'];

    print('💳 [DeepLinkService] Transaction ID: $transactionId');
    print('💳 [DeepLinkService] App Order ID: $appOrderId');
    print('💳 [DeepLinkService] Transaction Status: $transactionStatus');
    print('💳 [DeepLinkService] Status Code: $statusCode');

    // First, try to use the direct app_order_id if available
    if (appOrderId != null && appOrderId.isNotEmpty) {
      final orderId = int.tryParse(appOrderId);
      if (orderId != null && orderId > 0) {
        print('✅ [DeepLinkService] Using direct app_order_id: $orderId');
        _navigateTo('/order-status/$orderId');
        return;
      }
    }

    // Fallback: Parse from transaction_id format: TRX-{orderId}-{timestamp}
    if (transactionId != null && transactionId.isNotEmpty) {
      final orderId = _parseOrderIdFromTransactionId(transactionId);

      if (orderId != null) {
        print('✅ [DeepLinkService] Parsed order ID from transaction: $orderId');
        _navigateTo('/order-status/$orderId');
        return;
      } else {
        print(
          '⚠️ [DeepLinkService] Could not parse order ID from: $transactionId',
        );
      }
    }

    // Fallback: navigate to orders page if we can't parse the order ID
    print('⚠️ [DeepLinkService] Falling back to orders page');
    _navigateTo('/orders');
  }

  /// Parse order ID from transaction ID
  /// Transaction ID format: TRX-{orderId}-{timestamp}
  /// Example: TRX-123-1699999999 -> 123
  int? _parseOrderIdFromTransactionId(String transactionId) {
    try {
      // Split by dash
      final parts = transactionId.split('-');

      if (parts.length >= 2) {
        // Second part should be the order ID
        final orderIdStr = parts[1];
        final orderId = int.tryParse(orderIdStr);

        if (orderId != null && orderId > 0) {
          return orderId;
        }
      }

      // Try alternative parsing if format is different
      // Maybe just a number
      final directParse = int.tryParse(transactionId);
      if (directParse != null && directParse > 0) {
        return directParse;
      }

      return null;
    } catch (e) {
      print('❌ [DeepLinkService] Error parsing transaction ID: $e');
      return null;
    }
  }

  /// Navigate to the specified path
  void _navigateTo(String path) {
    print('🚀 [DeepLinkService] Navigating to: $path');

    if (onLinkReceived != null) {
      onLinkReceived!(path);
    } else {
      print('⚠️ [DeepLinkService] No navigation callback registered');
    }
  }

  /// Set the navigation callback
  /// Should be called after router is initialized
  void setNavigationCallback(Function(String path) callback) {
    onLinkReceived = callback;
    print('✅ [DeepLinkService] Navigation callback registered');
  }

  /// Dispose resources
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    print('🗑️ [DeepLinkService] Disposed');
  }
}
