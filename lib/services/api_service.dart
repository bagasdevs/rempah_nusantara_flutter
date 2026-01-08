import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class ApiService {
  // Base URL - API endpoint
  static const String baseUrl = 'https://api.bagas.website';

  static String? _token;
  static String? _userId;

  /// Initialize service - load token from storage
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _userId = prefs.getString('user_id');
  }

  /// Save token to storage
  static Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  /// Save user ID
  static Future<void> setUserId(String userId) async {
    _userId = userId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
  }

  /// Clear token and user data
  static Future<void> clearAuth() async {
    _token = null;
    _userId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
  }

  /// Get current user ID
  static String? get currentUserId => _userId;

  /// Check if user is authenticated
  static bool get isAuthenticated => _token != null;

  // ==================== HTTP METHODS ====================

  /// GET request
  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      // Add trailing slash for Apache compatibility (GET requests only)
      String url = '$baseUrl$endpoint';
      if (!endpoint.contains('?') && !url.endsWith('/')) {
        url = '$url/';
      }

      print('📥 [GET] $url');
      print('📥 [GET] Headers: ${_buildHeaders()}');

      final response = await http.get(Uri.parse(url), headers: _buildHeaders());

      print('✅ [GET] Status: ${response.statusCode}');

      return _handleResponse(response);
    } on SocketException catch (e) {
      print('❌ [GET] SocketException: $e');
      print('❌ Check internet connection and server availability');
      throw Exception(
        'Network error: Unable to connect to server. Check your internet connection.',
      );
    } on HandshakeException catch (e) {
      print('❌ [GET] HandshakeException: $e');
      print('❌ SSL/TLS error - check server certificate');
      throw Exception('SSL error: Server certificate issue. Contact support.');
    } on HttpException catch (e) {
      print('❌ [GET] HttpException: $e');
      throw Exception('HTTP error: $e');
    } catch (e) {
      print('❌ [GET] Unknown error: $e');
      print('❌ Error type: ${e.runtimeType}');
      throw Exception('Network error: $e');
    }
  }

  /// POST request
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final url = '$baseUrl$endpoint';
      print('📤 [POST] $url');
      print('📤 [POST] Headers: ${_buildHeaders()}');
      print('📤 [POST] Body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse(url),
        headers: _buildHeaders(),
        body: jsonEncode(body),
      );

      print('✅ [POST] Status: ${response.statusCode}');
      print('✅ [POST] Response: ${response.body}');

      return _handleResponse(response);
    } on SocketException catch (e) {
      print('❌ [POST] SocketException: $e');
      print('❌ Check internet connection and server availability');
      throw Exception(
        'Network error: Unable to connect to server. Check your internet connection.',
      );
    } on HandshakeException catch (e) {
      print('❌ [POST] HandshakeException: $e');
      print('❌ SSL/TLS error - check server certificate');
      throw Exception('SSL error: Server certificate issue. Contact support.');
    } on HttpException catch (e) {
      print('❌ [POST] HttpException: $e');
      throw Exception('HTTP error: $e');
    } catch (e) {
      print('❌ [POST] Error: $e');
      print('❌ Error type: ${e.runtimeType}');
      throw Exception('Network error: $e');
    }
  }

  /// PUT request
  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final url = '$baseUrl$endpoint';
      print('📝 [PUT] $url');
      print('📝 [PUT] Headers: ${_buildHeaders()}');
      print('📝 [PUT] Body: ${jsonEncode(body)}');

      final response = await http.put(
        Uri.parse(url),
        headers: _buildHeaders(),
        body: jsonEncode(body),
      );

      print('✅ [PUT] Status: ${response.statusCode}');
      print('✅ [PUT] Response: ${response.body}');

      return _handleResponse(response);
    } on SocketException catch (e) {
      print('❌ [PUT] SocketException: $e');
      throw Exception(
        'Network error: Unable to connect to server. Check your internet connection.',
      );
    } on HandshakeException catch (e) {
      print('❌ [PUT] HandshakeException: $e');
      throw Exception('SSL error: Server certificate issue. Contact support.');
    } catch (e) {
      print('❌ [PUT] Error: $e');
      throw Exception('Network error: $e');
    }
  }

  /// DELETE request
  static Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final url = '$baseUrl$endpoint';
      print('🗑️ [DELETE] $url');
      print('🗑️ [DELETE] Headers: ${_buildHeaders()}');

      final response = await http.delete(
        Uri.parse(url),
        headers: _buildHeaders(),
      );

      print('✅ [DELETE] Status: ${response.statusCode}');

      return _handleResponse(response);
    } on SocketException catch (e) {
      print('❌ [DELETE] SocketException: $e');
      throw Exception(
        'Network error: Unable to connect to server. Check your internet connection.',
      );
    } on HandshakeException catch (e) {
      print('❌ [DELETE] HandshakeException: $e');
      throw Exception('SSL error: Server certificate issue. Contact support.');
    } catch (e) {
      print('❌ [DELETE] Error: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Upload file (multipart)
  static Future<Map<String, dynamic>> uploadFile(
    String filePath,
    String bucket,
  ) async {
    try {
      final url = '$baseUrl/api/storage/upload';
      print('📤 [UPLOAD] $url');
      print('📤 [UPLOAD] File: $filePath');
      print('📤 [UPLOAD] Bucket: $bucket');

      var request = http.MultipartRequest('POST', Uri.parse(url));

      request.headers.addAll(_buildHeaders());
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      request.fields['bucket'] = bucket;

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('✅ [UPLOAD] Status: ${response.statusCode}');

      return _handleResponse(response);
    } on SocketException catch (e) {
      print('❌ [UPLOAD] SocketException: $e');
      throw Exception(
        'Network error: Unable to connect to server. Check your internet connection.',
      );
    } on HandshakeException catch (e) {
      print('❌ [UPLOAD] HandshakeException: $e');
      throw Exception('SSL error: Server certificate issue. Contact support.');
    } catch (e) {
      print('❌ [UPLOAD] Error: $e');
      throw Exception('Upload error: $e');
    }
  }

  // ==================== AUTH METHODS ====================

  /// Signup
  static Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    final result = await post('/api/auth/signup', {
      'email': email,
      'password': password,
      'data': data ?? {},
    });

    if (result['success'] == true) {
      await setToken(result['data']['access_token']);
      await setUserId(result['data']['user']['id']);
    }

    return result;
  }

  /// Login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    print('🔐 [ApiService] Attempting login for: $email');
    print('🔐 [ApiService] POST $baseUrl/api/auth/login');

    final result = await post('/api/auth/login', {
      'email': email,
      'password': password,
    });

    print('🔐 [ApiService] Login response: ${result['success']}');

    if (result['success'] == true) {
      await setToken(result['data']['access_token']);
      await setUserId(result['data']['user']['id']);
      print(
        '🔐 [ApiService] Token saved, user ID: ${result['data']['user']['id']}',
      );
    } else {
      print('❌ [ApiService] Login failed: ${result['message']}');
    }

    return result;
  }

  /// Logout
  static Future<void> logout() async {
    try {
      // Delete FCM token from server
      await NotificationService.deleteToken();
    } catch (e) {
      print('FCM token delete error (ignored): $e');
    }
    try {
      await post('/api/auth/logout', {});
    } catch (e) {
      print('Logout API error (ignored): $e');
    }
    await clearAuth();
  }

  /// Delete account permanently
  static Future<void> deleteAccount({required String confirmText}) async {
    final result = await post('/api/auth/delete-account', {
      'confirm': confirmText,
    });

    if (result['success'] == true) {
      // Clear local auth data
      await clearAuth();
    } else {
      throw Exception(result['message'] ?? 'Failed to delete account');
    }
  }

  /// Get current user
  static Future<Map<String, dynamic>> getCurrentUser() async {
    print('📡 [API] Fetching current user from /api/auth/user');
    final result = await get('/api/auth/user');
    print('📦 [API] getCurrentUser response: $result');
    return result;
  }

  // ==================== PRODUCTS METHODS ====================

  /// Get products list
  static Future<List<Map<String, dynamic>>> getProducts({
    int? categoryId,
    String? sellerId,
    String? search,
    int limit = 50,
    int offset = 0,
    String orderBy = 'created_at',
    String orderDir = 'DESC',
  }) async {
    String endpoint =
        '/api/products?limit=$limit&offset=$offset&order_by=$orderBy&order_dir=$orderDir';

    if (categoryId != null) {
      endpoint += '&category_id=$categoryId';
    }

    if (sellerId != null) {
      endpoint += '&seller_id=$sellerId';
    }

    if (search != null && search.isNotEmpty) {
      endpoint += '&search=${Uri.encodeComponent(search)}';
    }

    final result = await get(endpoint);

    if (result['success'] == true) {
      return List<Map<String, dynamic>>.from(result['data']);
    } else {
      throw Exception(result['message']);
    }
  }

  /// Get product detail
  static Future<Map<String, dynamic>> getProductDetail(int productId) async {
    final result = await get('/api/products/detail?id=$productId');

    if (result['success'] == true) {
      return result['data'];
    } else {
      throw Exception(result['message']);
    }
  }

  /// Create product
  static Future<Map<String, dynamic>> createProduct({
    required String name,
    required double price,
    required int stock,
    String? description,
    int? categoryId,
    String? imageUrl,
  }) async {
    final result = await post('/api/products', {
      'name': name,
      'price': price,
      'stock': stock,
      if (description != null) 'description': description,
      if (categoryId != null) 'category_id': categoryId,
      if (imageUrl != null) 'image_url': imageUrl,
    });

    if (result['success'] == true) {
      return result['data'];
    } else {
      throw Exception(result['message']);
    }
  }

  /// Update product
  static Future<Map<String, dynamic>> updateProduct({
    required int productId,
    String? name,
    double? price,
    int? stock,
    String? description,
    int? categoryId,
    String? imageUrl,
  }) async {
    final result = await put('/api/products/detail?id=$productId', {
      if (name != null) 'name': name,
      if (price != null) 'price': price,
      if (stock != null) 'stock': stock,
      if (description != null) 'description': description,
      if (categoryId != null) 'category_id': categoryId,
      if (imageUrl != null) 'image_url': imageUrl,
    });

    if (result['success'] == true) {
      return result['data'];
    } else {
      throw Exception(result['message']);
    }
  }

  /// Delete product
  static Future<void> deleteProduct(int productId) async {
    final result = await delete('/api/products/detail?id=$productId');

    if (result['success'] != true) {
      throw Exception(result['message']);
    }
  }

  // ==================== CATEGORIES METHODS ====================

  /// Get categories
  static Future<List<Map<String, dynamic>>> getCategories({
    int limit = 100,
  }) async {
    final result = await get('/api/categories?limit=$limit');

    if (result['success'] == true) {
      return List<Map<String, dynamic>>.from(result['data']['categories']);
    } else {
      throw Exception(result['message']);
    }
  }

  // ==================== CART METHODS ====================

  /// Get cart items
  static Future<Map<String, dynamic>> getCart() async {
    final result = await get('/api/cart');

    if (result['success'] == true) {
      return result['data'];
    } else {
      throw Exception(result['message']);
    }
  }

  /// Add to cart
  static Future<Map<String, dynamic>> addToCart({
    required int productId,
    required int quantity,
  }) async {
    final result = await post('/api/cart', {
      'product_id': productId,
      'quantity': quantity,
    });

    if (result['success'] == true) {
      return result['data'];
    } else {
      throw Exception(result['message']);
    }
  }

  /// Update cart item
  static Future<Map<String, dynamic>> updateCartItem({
    required int cartItemId,
    required int quantity,
  }) async {
    final result = await put('/api/cart/detail?id=$cartItemId', {
      'quantity': quantity,
    });

    if (result['success'] == true) {
      return result['data'];
    } else {
      throw Exception(result['message']);
    }
  }

  /// Remove from cart
  static Future<void> removeFromCart(int cartItemId) async {
    final result = await delete('/api/cart/detail?id=$cartItemId');

    if (result['success'] != true) {
      throw Exception(result['message']);
    }
  }

  // ==================== ORDERS METHODS ====================

  /// Create order from cart
  static Future<Map<String, dynamic>> createOrderFromCart({
    required double totalAmount,
    required double shippingFee,
    required String shippingAddress,
    required String paymentMethod,
  }) async {
    final result = await post('/api/orders/create-from-cart', {
      'p_total_amount': totalAmount,
      'p_shipping_fee': shippingFee,
      'p_shipping_address': shippingAddress,
      'p_payment_method': paymentMethod,
    });

    if (result['success'] == true) {
      return result['data'];
    } else {
      throw Exception(result['message']);
    }
  }

  /// Get user orders
  static Future<List<Map<String, dynamic>>> getOrders({
    String? status,
    int? limit,
    int? offset,
  }) async {
    print('📡 [API] Fetching orders from /api/orders');

    final params = <String, String>{};
    if (status != null) params['status'] = status;
    if (limit != null) params['limit'] = limit.toString();
    if (offset != null) params['offset'] = offset.toString();

    final queryString = params.isEmpty
        ? ''
        : '?' + params.entries.map((e) => '${e.key}=${e.value}').join('&');

    print('📡 [API] Query string: $queryString');

    final result = await get('/api/orders$queryString');

    print('📦 [API] getOrders response: $result');

    if (result['success'] == true) {
      final orders = List<Map<String, dynamic>>.from(result['data'] ?? []);
      print('✅ [API] Successfully parsed ${orders.length} orders');
      return orders;
    } else {
      print('❌ [API] Failed to get orders: ${result['message']}');
      throw Exception(result['message']);
    }
  }

  /// Get order detail
  static Future<Map<String, dynamic>> getOrderDetail(int orderId) async {
    final result = await get('/api/orders/detail?id=$orderId');

    if (result['success'] == true) {
      return result['data'];
    } else {
      throw Exception(result['message']);
    }
  }

  // ==================== PAYMENT METHODS (MIDTRANS) ====================

  /// Create payment transaction (get Snap token)
  static Future<Map<String, dynamic>> createPaymentTransaction({
    required int orderId,
    required double grossAmount,
    required List<Map<String, dynamic>> items,
    Map<String, dynamic>? customer,
    Map<String, dynamic>? shippingAddress,
    double? shippingCost,
    String? finishRedirectUrl,
  }) async {
    final result = await post('/api/payments/create-transaction', {
      'order_id': orderId,
      'gross_amount': grossAmount,
      'items': items,
      if (customer != null) 'customer': customer,
      if (shippingAddress != null) 'shipping_address': shippingAddress,
      if (shippingCost != null) 'shipping_cost': shippingCost,
      if (finishRedirectUrl != null) 'finish_redirect_url': finishRedirectUrl,
    });

    if (result['success'] == true) {
      return result['data'];
    } else {
      throw Exception(result['message']);
    }
  }

  /// Check payment status
  static Future<Map<String, dynamic>> checkPaymentStatus(int orderId) async {
    final result = await get('/api/payments/status?order_id=$orderId');

    if (result['success'] == true) {
      return result;
    } else {
      throw Exception(result['message']);
    }
  }

  // ==================== ADDRESSES METHODS ====================

  /// Get all addresses
  static Future<List<Map<String, dynamic>>> getAddresses() async {
    print('📡 [API] Fetching addresses from /api/addresses');
    final result = await get('/api/addresses');

    print('📦 [API] getAddresses response: $result');

    if (result['success'] == true) {
      final addresses = List<Map<String, dynamic>>.from(result['data']);
      print('✅ [API] Successfully parsed ${addresses.length} addresses');
      return addresses;
    } else {
      print('❌ [API] Failed to get addresses: ${result['message']}');
      throw Exception(result['message']);
    }
  }

  /// Get address detail
  static Future<Map<String, dynamic>> getAddressDetail(int addressId) async {
    final result = await get('/api/addresses/detail?id=$addressId');

    if (result['success'] == true) {
      return result['data'];
    } else {
      throw Exception(result['message']);
    }
  }

  /// Create address
  static Future<Map<String, dynamic>> createAddress({
    required String label,
    required String recipientName,
    required String phone,
    required String address,
    String? city,
    String? province,
    String? postalCode,
    double? latitude,
    double? longitude,
    String? notes,
    bool? isDefault,
  }) async {
    final result = await post('/api/addresses', {
      'label': label,
      'recipient_name': recipientName,
      'phone': phone,
      'address': address,
      if (city != null) 'city': city,
      if (province != null) 'province': province,
      if (postalCode != null) 'postal_code': postalCode,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (notes != null) 'notes': notes,
      if (isDefault != null) 'is_default': isDefault,
    });

    if (result['success'] == true) {
      return result['data'];
    } else {
      throw Exception(result['message']);
    }
  }

  /// Update address
  static Future<Map<String, dynamic>> updateAddress({
    required int addressId,
    String? label,
    String? recipientName,
    String? phone,
    String? address,
    String? city,
    String? province,
    String? postalCode,
    double? latitude,
    double? longitude,
    String? notes,
    bool? isDefault,
  }) async {
    final result = await put('/api/addresses/detail?id=$addressId', {
      if (label != null) 'label': label,
      if (recipientName != null) 'recipient_name': recipientName,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (province != null) 'province': province,
      if (postalCode != null) 'postal_code': postalCode,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (notes != null) 'notes': notes,
      if (isDefault != null) 'is_default': isDefault,
    });

    if (result['success'] == true) {
      return result['data'];
    } else {
      throw Exception(result['message']);
    }
  }

  /// Delete address
  static Future<void> deleteAddress(int addressId) async {
    final result = await delete('/api/addresses/detail?id=$addressId');

    if (result['success'] != true) {
      throw Exception(result['message']);
    }
  }

  // ==================== FAVORITES METHODS ====================

  /// Get all favorited products
  static Future<List<Map<String, dynamic>>> getFavorites() async {
    final result = await get('/api/favorites');

    if (result['success'] == true) {
      return List<Map<String, dynamic>>.from(result['data']);
    } else {
      throw Exception(result['message']);
    }
  }

  /// Add product to favorites
  static Future<Map<String, dynamic>> addToFavorites(int productId) async {
    final result = await post('/api/favorites', {'product_id': productId});

    if (result['success'] == true) {
      return result['data'];
    } else {
      throw Exception(result['message']);
    }
  }

  /// Remove product from favorites
  static Future<void> removeFromFavorites(int productId) async {
    final result = await delete('/api/favorites?product_id=$productId');

    if (result['success'] != true) {
      throw Exception(result['message']);
    }
  }

  // ==================== REVIEWS METHODS ====================

  /// Get product reviews
  static Future<Map<String, dynamic>> getProductReviews({
    required int productId,
    int page = 1,
    int limit = 10,
    int? rating,
  }) async {
    String endpoint =
        '/api/reviews?product_id=$productId&page=$page&limit=$limit';

    if (rating != null) {
      endpoint += '&rating=$rating';
    }

    final result = await get(endpoint);

    if (result['success'] == true) {
      return {
        'reviews': List<Map<String, dynamic>>.from(result['data']),
        'pagination': result['pagination'],
        'rating_summary': result['rating_summary'],
      };
    } else {
      throw Exception(result['message']);
    }
  }

  /// Create product review
  static Future<Map<String, dynamic>> createReview({
    required int productId,
    required int rating,
    required String comment,
    int? orderId,
    List<String>? images,
  }) async {
    final result = await post('/api/reviews', {
      'product_id': productId,
      'rating': rating,
      'comment': comment,
      if (orderId != null) 'order_id': orderId,
      if (images != null) 'images': images,
    });

    if (result['success'] == true) {
      return result['data'];
    } else {
      throw Exception(result['message']);
    }
  }

  // ==================== NOTIFICATIONS METHODS ====================

  /// Get notifications
  static Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? isRead,
    String? type,
  }) async {
    String endpoint = '/api/notifications?page=$page&limit=$limit';

    if (isRead != null) {
      endpoint += '&is_read=$isRead';
    }

    if (type != null) {
      endpoint += '&type=$type';
    }

    final result = await get(endpoint);

    if (result['success'] == true) {
      return {
        'notifications': List<Map<String, dynamic>>.from(result['data']),
        'pagination': result['pagination'],
        'unread_count': result['unread_count'],
      };
    } else {
      throw Exception(result['message']);
    }
  }

  /// Mark notification(s) as read
  static Future<void> markNotificationsAsRead({
    int? notificationId,
    List<int>? notificationIds,
    bool markAll = false,
  }) async {
    Map<String, dynamic> body = {};

    if (markAll) {
      body['mark_all'] = true;
    } else if (notificationId != null) {
      body['notification_id'] = notificationId;
    } else if (notificationIds != null) {
      body['notification_ids'] = notificationIds;
    }

    final result = await post('/api/notifications/mark-read', body);

    if (result['success'] != true) {
      throw Exception(result['message']);
    }
  }

  // ==================== PROFILE METHODS ====================

  /// Get profile
  static Future<Map<String, dynamic>> getProfile(String userId) async {
    final result = await get('/api/profiles/detail?id=$userId');

    if (result['success'] == true) {
      return result['data'];
    } else {
      throw Exception(result['message']);
    }
  }

  /// Update profile
  static Future<Map<String, dynamic>> updateProfile({
    required String userId,
    String? fullName,
    String? address,
    String? mobileNumber,
    String? dateOfBirth,
  }) async {
    final result = await put('/api/profiles/detail?id=$userId', {
      if (fullName != null) 'full_name': fullName,
      if (address != null) 'address': address,
      if (mobileNumber != null) 'mobile_number': mobileNumber,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
    });

    if (result['success'] == true) {
      return result['data'];
    } else {
      throw Exception(result['message']);
    }
  }

  // ==================== SELLER METHODS ====================

  /// Register as seller (upgrade from buyer to seller)
  static Future<Map<String, dynamic>> registerSeller({
    required String businessName,
    required String address,
  }) async {
    final result = await post('/api/seller/register', {
      'business_name': businessName,
      'address': address,
    });

    if (result['success'] == true) {
      return result['data'];
    } else {
      throw Exception(result['message'] ?? 'Failed to register as seller');
    }
  }

  /// Get seller dashboard analytics
  static Future<Map<String, dynamic>> getSellerDashboard({
    int days = 30,
  }) async {
    final result = await get('/api/seller/dashboard?days=$days');

    if (result['success'] == true) {
      return result['data'];
    } else {
      throw Exception(result['message'] ?? 'Failed to get seller dashboard');
    }
  }

  /// Get seller orders
  static Future<List<Map<String, dynamic>>> getSellerOrders({
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    String endpoint = '/api/seller/orders?limit=$limit&offset=$offset';
    if (status != null) {
      endpoint += '&status=$status';
    }

    final result = await get(endpoint);

    if (result['success'] == true) {
      return List<Map<String, dynamic>>.from(result['data'] ?? []);
    } else {
      throw Exception(result['message'] ?? 'Failed to get seller orders');
    }
  }

  // ==================== ADMIN API ====================

  /// Get admin dashboard analytics
  static Future<Map<String, dynamic>> getAdminDashboard({int days = 30}) async {
    final result = await get('/api/admin/dashboard?days=$days');

    if (result['success'] == true) {
      return result['data'];
    } else {
      throw Exception(result['message'] ?? 'Failed to get admin dashboard');
    }
  }

  /// Get admin users list
  static Future<Map<String, dynamic>> getAdminUsers({
    int limit = 20,
    int offset = 0,
    String? role,
    String? status,
    String? search,
    String sortBy = 'created_at',
    String sortOrder = 'DESC',
  }) async {
    String endpoint = '/api/admin/users?limit=$limit&offset=$offset';
    endpoint += '&sort_by=$sortBy&sort_order=$sortOrder';
    if (role != null) endpoint += '&role=$role';
    if (status != null) endpoint += '&status=$status';
    if (search != null && search.isNotEmpty) endpoint += '&search=$search';

    final result = await get(endpoint);

    if (result['success'] == true) {
      return {
        'users': List<Map<String, dynamic>>.from(result['data'] ?? []),
        'pagination': result['pagination'] ?? {},
      };
    } else {
      throw Exception(result['message'] ?? 'Failed to get users');
    }
  }

  /// Get single user details (admin)
  static Future<Map<String, dynamic>> getAdminUserDetail(String userId) async {
    final result = await get('/api/admin/users?id=$userId');

    if (result['success'] == true) {
      return result['data'];
    } else {
      throw Exception(result['message'] ?? 'Failed to get user details');
    }
  }

  /// Update user (role, ban status) - Admin
  static Future<Map<String, dynamic>> updateAdminUser({
    required String userId,
    String? role,
    bool? isBanned,
    String? banReason,
  }) async {
    final body = <String, dynamic>{'user_id': userId};
    if (role != null) body['role'] = role;
    if (isBanned != null) body['is_banned'] = isBanned;
    if (banReason != null) body['ban_reason'] = banReason;

    final result = await put('/api/admin/users', body);

    if (result['success'] == true) {
      return result['data'];
    } else {
      throw Exception(result['message'] ?? 'Failed to update user');
    }
  }

  /// Delete user - Admin
  static Future<void> deleteAdminUser(String userId) async {
    final result = await delete('/api/admin/users?id=$userId');

    if (result['success'] != true) {
      throw Exception(result['message'] ?? 'Failed to delete user');
    }
  }

  /// Get admin products list
  static Future<Map<String, dynamic>> getAdminProducts({
    int limit = 20,
    int offset = 0,
    int? categoryId,
    String? sellerId,
    String? status,
    String? stockStatus,
    String? search,
    String sortBy = 'created_at',
    String sortOrder = 'DESC',
  }) async {
    String endpoint = '/api/admin/products?limit=$limit&offset=$offset';
    endpoint += '&sort_by=$sortBy&sort_order=$sortOrder';
    if (categoryId != null) endpoint += '&category_id=$categoryId';
    if (sellerId != null) endpoint += '&seller_id=$sellerId';
    if (status != null) endpoint += '&status=$status';
    if (stockStatus != null) endpoint += '&stock_status=$stockStatus';
    if (search != null && search.isNotEmpty) endpoint += '&search=$search';

    final result = await get(endpoint);

    if (result['success'] == true) {
      return {
        'products': List<Map<String, dynamic>>.from(result['data'] ?? []),
        'pagination': result['pagination'] ?? {},
      };
    } else {
      throw Exception(result['message'] ?? 'Failed to get products');
    }
  }

  /// Get single product details (admin)
  static Future<Map<String, dynamic>> getAdminProductDetail(
    int productId,
  ) async {
    final result = await get('/api/admin/products?id=$productId');

    if (result['success'] == true) {
      return result['data'];
    } else {
      throw Exception(result['message'] ?? 'Failed to get product details');
    }
  }

  /// Update product (status, featured, approved) - Admin
  static Future<Map<String, dynamic>> updateAdminProduct({
    required int productId,
    bool? isActive,
    bool? isFeatured,
    bool? isApproved,
    int? categoryId,
    String? rejectionReason,
  }) async {
    final body = <String, dynamic>{'product_id': productId};
    if (isActive != null) body['is_active'] = isActive;
    if (isFeatured != null) body['is_featured'] = isFeatured;
    if (isApproved != null) body['is_approved'] = isApproved;
    if (categoryId != null) body['category_id'] = categoryId;
    if (rejectionReason != null) body['rejection_reason'] = rejectionReason;

    final result = await put('/api/admin/products', body);

    if (result['success'] == true) {
      return result['data'];
    } else {
      throw Exception(result['message'] ?? 'Failed to update product');
    }
  }

  /// Delete product - Admin
  static Future<Map<String, dynamic>> deleteAdminProduct(int productId) async {
    final result = await delete('/api/admin/products?id=$productId');

    if (result['success'] == true) {
      return result['data'] ?? {};
    } else {
      throw Exception(result['message'] ?? 'Failed to delete product');
    }
  }

  /// Get admin orders list
  static Future<Map<String, dynamic>> getAdminOrders({
    int limit = 20,
    int offset = 0,
    String? status,
    String? paymentStatus,
    String? buyerId,
    String? sellerId,
    String? search,
    String? dateFrom,
    String? dateTo,
    String sortBy = 'created_at',
    String sortOrder = 'DESC',
  }) async {
    String endpoint = '/api/admin/orders?limit=$limit&offset=$offset';
    endpoint += '&sort_by=$sortBy&sort_order=$sortOrder';
    if (status != null) endpoint += '&status=$status';
    if (paymentStatus != null) endpoint += '&payment_status=$paymentStatus';
    if (buyerId != null) endpoint += '&buyer_id=$buyerId';
    if (sellerId != null) endpoint += '&seller_id=$sellerId';
    if (search != null && search.isNotEmpty) endpoint += '&search=$search';
    if (dateFrom != null) endpoint += '&date_from=$dateFrom';
    if (dateTo != null) endpoint += '&date_to=$dateTo';

    final result = await get(endpoint);

    if (result['success'] == true) {
      return {
        'orders': List<Map<String, dynamic>>.from(result['data'] ?? []),
        'pagination': result['pagination'] ?? {},
        'stats': result['stats'] ?? {},
      };
    } else {
      throw Exception(result['message'] ?? 'Failed to get orders');
    }
  }

  /// Get single order details (admin)
  static Future<Map<String, dynamic>> getAdminOrderDetail(int orderId) async {
    final result = await get('/api/admin/orders?id=$orderId');

    if (result['success'] == true) {
      return result['data'];
    } else {
      throw Exception(result['message'] ?? 'Failed to get order details');
    }
  }

  /// Update order (status, payment, tracking) - Admin
  static Future<Map<String, dynamic>> updateAdminOrder({
    required int orderId,
    String? status,
    String? paymentStatus,
    String? trackingNumber,
    String? adminNotes,
    String? statusNotes,
  }) async {
    final body = <String, dynamic>{'order_id': orderId};
    if (status != null) body['status'] = status;
    if (paymentStatus != null) body['payment_status'] = paymentStatus;
    if (trackingNumber != null) body['tracking_number'] = trackingNumber;
    if (adminNotes != null) body['admin_notes'] = adminNotes;
    if (statusNotes != null) body['status_notes'] = statusNotes;

    final result = await put('/api/admin/orders', body);

    if (result['success'] == true) {
      return result['data'];
    } else {
      throw Exception(result['message'] ?? 'Failed to update order');
    }
  }

  /// Cancel order - Admin
  static Future<Map<String, dynamic>> cancelAdminOrder(
    int orderId, {
    String? reason,
  }) async {
    String endpoint = '/api/admin/orders?id=$orderId';
    if (reason != null && reason.isNotEmpty) {
      endpoint += '&reason=${Uri.encodeComponent(reason)}';
    }

    final result = await delete(endpoint);

    if (result['success'] == true) {
      return result['data'] ?? {};
    } else {
      throw Exception(result['message'] ?? 'Failed to cancel order');
    }
  }

  // ==================== HELPER METHODS ====================

  static Map<String, String> _buildHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return body;
      } else {
        final errorMessage = body['message'] ?? 'Request failed';
        print('⚠️ [Response] Error ${response.statusCode}: $errorMessage');
        throw Exception(errorMessage);
      }
    } on FormatException catch (e) {
      print('❌ [Response] JSON Parse Error: $e');
      print('❌ [Response] Body: ${response.body}');
      throw Exception('Invalid response format from server');
    } catch (e) {
      print('❌ [Response] Error: $e');
      rethrow;
    }
  }
}
