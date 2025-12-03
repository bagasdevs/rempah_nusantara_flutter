import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:midtrans_sdk/midtrans_sdk.dart';
import 'api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentService {
  static MidtransSDK? _midtransSDK;
  static bool _isInitialized = false;

  /// Initialize Midtrans SDK
  static Future<void> init({
    required String clientKey,
    required bool isProduction,
  }) async {
    if (_isInitialized) return;

    // Skip SDK initialization on web
    if (kIsWeb) {
      _isInitialized = true;
      print(
        '✅ [PaymentService] Web platform detected - using redirect URL method',
      );
      return;
    }

    _midtransSDK = await MidtransSDK.init(
      config: MidtransConfig(
        clientKey: clientKey,
        merchantBaseUrl: '', // Not needed for Snap
        colorTheme: ColorTheme(
          colorPrimary: Color(0xFF2E7D32),
          colorPrimaryDark: Color(0xFF1B5E20),
          colorSecondary: Color(0xFF66BB6A),
        ),
      ),
    );

    _isInitialized = true;
    print(
      '✅ [PaymentService] Midtrans SDK initialized (production: $isProduction)',
    );
  }

  /// Create payment and get Snap token
  static Future<Map<String, dynamic>> createPayment({
    required int orderId,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
    Map<String, dynamic>? customer,
    Map<String, dynamic>? shippingAddress,
    double? shippingCost,
  }) async {
    try {
      print('💳 [PaymentService] Creating payment for order #$orderId');
      print(
        '💳 [PaymentService] Total amount: Rp ${totalAmount.toStringAsFixed(0)}',
      );

      // Call backend to create transaction and get Snap token
      final response = await ApiService.createPaymentTransaction(
        orderId: orderId,
        grossAmount: totalAmount,
        items: items,
        customer: customer,
        shippingAddress: shippingAddress,
        shippingCost: shippingCost,
      );

      print('✅ [PaymentService] Snap token received');
      print(
        '💳 [PaymentService] Transaction ID: ${response['transaction_id']}',
      );

      return response;
    } catch (e) {
      print('❌ [PaymentService] Create payment error: $e');
      rethrow;
    }
  }

  /// Start payment with Snap token or redirect URL
  static Future<Map<String, dynamic>?> startPayment({
    required String snapToken,
    String? redirectUrl,
  }) async {
    try {
      // For web, use redirect URL
      if (kIsWeb) {
        if (redirectUrl == null || redirectUrl.isEmpty) {
          throw Exception('Redirect URL is required for web platform');
        }

        print('💳 [PaymentService] Opening payment page');
        print('🔗 [PaymentService] URL: $redirectUrl');

        // Open payment page in browser
        final uri = Uri.parse(redirectUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          print('✅ [PaymentService] Payment page opened');
        } else {
          throw Exception('Could not launch payment URL');
        }

        // Return pending status - actual status will be checked via webhook/callback
        return {
          'status': 'pending',
          'message': 'Payment page opened in new tab',
        };
      }

      // For mobile, use SDK
      if (_midtransSDK == null) {
        throw Exception('Midtrans SDK not initialized. Call init() first.');
      }

      print('💳 [PaymentService] Starting payment with Snap token');

      // Start payment UI flow
      await _midtransSDK!.startPaymentUiFlow(token: snapToken);

      print('✅ [PaymentService] Payment UI completed');

      // Return basic success response
      return {'status': 'completed', 'message': 'Payment UI flow completed'};
    } catch (e) {
      print('❌ [PaymentService] Start payment error: $e');
      rethrow;
    }
  }

  /// Check payment status from backend
  static Future<Map<String, dynamic>> checkPaymentStatus(int orderId) async {
    try {
      print('🔍 [PaymentService] Checking payment status for order #$orderId');

      final response = await ApiService.checkPaymentStatus(orderId);

      print('✅ [PaymentService] Payment status retrieved');
      print('💳 [PaymentService] Status: ${response['payment_status']}');

      return response;
    } catch (e) {
      print('❌ [PaymentService] Check status error: $e');
      rethrow;
    }
  }

  /// Process complete payment flow
  static Future<Map<String, dynamic>> processPayment({
    required BuildContext context,
    required int orderId,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
    Map<String, dynamic>? customer,
    Map<String, dynamic>? shippingAddress,
    double? shippingCost,
  }) async {
    try {
      print('🚀 [PaymentService] Starting payment process for order #$orderId');

      // Step 1: Create payment transaction and get Snap token
      final paymentData = await createPayment(
        orderId: orderId,
        totalAmount: totalAmount,
        items: items,
        customer: customer,
        shippingAddress: shippingAddress,
        shippingCost: shippingCost,
      );

      final snapToken = paymentData['snap_token'];
      if (snapToken == null || snapToken.isEmpty) {
        throw Exception('Failed to get Snap token from server');
      }

      // Step 2: Start Midtrans payment UI
      final redirectUrl = paymentData['redirect_url'];
      await startPayment(snapToken: snapToken, redirectUrl: redirectUrl);

      // Step 3: For web, return pending status immediately
      // Actual status will be updated via webhook
      if (kIsWeb) {
        return {
          'payment_status': 'pending',
          'message': 'Payment page opened. Please complete payment in new tab.',
        };
      }

      // Step 3: For mobile, check payment status from backend
      final statusResponse = await checkPaymentStatus(orderId);

      print('✅ [PaymentService] Payment process completed');
      print(
        '💳 [PaymentService] Final status: ${statusResponse['payment_status']}',
      );

      return statusResponse;
    } catch (e) {
      print('❌ [PaymentService] Payment process error: $e');
      rethrow;
    }
  }

  /// Start polling order status
  /// Returns a Timer that can be cancelled
  static Timer startPollingOrderStatus(
    int orderId,
    Function(Map<String, dynamic>) onUpdate, {
    Duration interval = const Duration(seconds: 10),
    int maxPolls = 30, // Poll for max 5 minutes (30 * 10 seconds)
  }) {
    print('🔄 [PaymentService] Starting to poll order #$orderId status...');
    print(
      '⏱️ [PaymentService] Polling every ${interval.inSeconds}s, max $maxPolls times',
    );

    int pollCount = 0;

    return Timer.periodic(interval, (timer) async {
      pollCount++;

      try {
        print('📡 [PaymentService] Polling attempt $pollCount/$maxPolls');

        final response = await ApiService.checkPaymentStatus(orderId);

        if (response['success'] == true && response['data'] != null) {
          final order = response['data'];
          final paymentStatus = order['payment_status'];
          final orderStatus = order['status'];

          print(
            '📊 [PaymentService] Order status: $orderStatus, Payment: $paymentStatus',
          );

          // Call update callback
          onUpdate(order);

          // Stop polling if payment is complete (success or failed)
          if (paymentStatus == 'paid' ||
              paymentStatus == 'settlement' ||
              paymentStatus == 'failed' ||
              paymentStatus == 'expired' ||
              paymentStatus == 'cancelled') {
            print('✅ [PaymentService] Payment finalized: $paymentStatus');
            timer.cancel();
            return;
          }
        }

        // Stop after max polls
        if (pollCount >= maxPolls) {
          print('⏱️ [PaymentService] Max polling attempts reached');
          timer.cancel();
        }
      } catch (e) {
        print('❌ [PaymentService] Polling error: $e');
        // Continue polling even on error unless max reached
        if (pollCount >= maxPolls) {
          print('⏱️ [PaymentService] Max polling attempts reached after error');
          timer.cancel();
        }
      }
    });
  }

  /// Dispose SDK resources
  static void dispose() {
    _midtransSDK = null;
    _isInitialized = false;
    print('🗑️ [PaymentService] SDK disposed');
  }
}
