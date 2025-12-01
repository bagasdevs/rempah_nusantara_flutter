import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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

      final response = await http.get(Uri.parse(url), headers: _buildHeaders());
      return _handleResponse(response);
    } catch (e) {
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

      print('📥 [POST] Status: ${response.statusCode}');
      print('📥 [POST] Response: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('❌ [POST] Error: $e');
      throw Exception('Network error: $e');
    }
  }

  /// PUT request
  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _buildHeaders(),
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// DELETE request
  static Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _buildHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Upload file (multipart)
  static Future<Map<String, dynamic>> uploadFile(
    String filePath,
    String bucket,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/storage/upload'),
      );

      request.headers.addAll(_buildHeaders());
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      request.fields['bucket'] = bucket;

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
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
    await clearAuth();
  }

  /// Get current user
  static Future<Map<String, dynamic>> getCurrentUser() async {
    return await get('/api/auth/user');
  }

  // ==================== PRODUCTS METHODS ====================

  /// Get products list
  static Future<List<Map<String, dynamic>>> getProducts({
    int? categoryId,
    String? sellerId,
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
    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      throw Exception(body['message'] ?? 'Request failed');
    }
  }
}
