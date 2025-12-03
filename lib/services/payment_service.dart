import 'package:flutter/material.dart';
import 'package:midtrans_sdk/midtrans_sdk.dart';
import 'api_service.dart';

class PaymentService {
  static MidtransSDK? _midtransSDK;
  static bool _isInitialized = false;

  /// Initialize Midtrans SDK
  static Future<void> init({
    required String clientKey,
    required bool isProduction,
  }) async {
    if (_isInitialized) return;

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

  /// Start payment with Snap token
  static Future<Map<String, dynamic>?> startPayment({
    required String snapToken,
  }) async {
    try {
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
      await startPayment(snapToken: snapToken);

      // Step 3: Check payment status from backend
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

  /// Dispose SDK resources
  static void dispose() {
    _midtransSDK = null;
    _isInitialized = false;
    print('🗑️ [PaymentService] SDK disposed');
  }
}
