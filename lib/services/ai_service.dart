import 'dart:convert';
import 'package:http/http.dart' as http;

/// AI Service for Rempah Nusantara
///
/// Provides access to AI-powered features hosted on Hugging Face Spaces:
/// - Price Prediction (LSTM)
/// - Sentiment Analysis (CNN-LSTM)
/// - Anomaly Detection (Isolation Forest)
class AiService {
  // Hugging Face Space URL
  static const String _baseUrl =
      'https://bagasdev-rempah-nusantara-ai.hf.space';

  // HTTP timeout duration
  static const Duration _timeout = Duration(seconds: 30);

  /// Build headers for API requests
  static Map<String, String> _buildHeaders() {
    return {'Content-Type': 'application/json', 'Accept': 'application/json'};
  }

  /// Make POST request to HF Space
  static Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final url = '$_baseUrl$endpoint';
    print('🤖 [AI] POST $url');
    print('🤖 [AI] Body: $body');

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: _buildHeaders(),
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      print('🤖 [AI] Status: ${response.statusCode}');
      print('🤖 [AI] Response: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'AI service error');
      }
    } catch (e) {
      print('❌ [AI] Error: $e');
      rethrow;
    }
  }

  /// Make GET request to HF Space
  static Future<Map<String, dynamic>> _get(String endpoint) async {
    final url = '$_baseUrl$endpoint';
    print('🤖 [AI] GET $url');

    try {
      final response = await http
          .get(Uri.parse(url), headers: _buildHeaders())
          .timeout(_timeout);

      print('🤖 [AI] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('AI service error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [AI] Error: $e');
      rethrow;
    }
  }

  // ==================== HEALTH CHECK ====================

  /// Check if AI service is available
  static Future<bool> isAvailable() async {
    try {
      final result = await _get('/');
      return result['success'] == true;
    } catch (e) {
      print('❌ [AI] Health check failed: $e');
      return false;
    }
  }

  // ==================== PRICE PREDICTION ====================

  /// Predict optimal price based on 10 historical prices
  ///
  /// [historicalPrices] - List of exactly 10 historical prices
  /// [productId] - Optional product ID for per-product prediction
  /// [productName] - Optional product name for display
  /// Returns prediction result with predicted price and analysis
  static Future<PricePredictionResult> predictPrice(
    List<double> historicalPrices, {
    int? productId,
    String? productName,
  }) async {
    if (historicalPrices.length != 10) {
      throw Exception('Exactly 10 historical prices are required');
    }

    if (historicalPrices.any((price) => price <= 0)) {
      throw Exception('All prices must be positive');
    }

    try {
      final result = await _post('/predict/price', {'data': historicalPrices});

      if (result['success'] == true && result['data'] != null) {
        return PricePredictionResult.fromJson(
          result['data'],
          productId: productId,
          productName: productName,
        );
      } else {
        final error = result['error'];
        throw Exception(error?['message'] ?? 'Price prediction failed');
      }
    } catch (e) {
      print('❌ [AI] Price prediction error: $e');
      rethrow;
    }
  }

  /// Get price history for a specific product
  ///
  /// [productId] - Product ID to get history for
  /// [days] - Number of days of history (default: 10)
  /// Returns ProductPriceHistory with product info and price list
  static Future<ProductPriceHistory> getProductPriceHistory(
    int productId, {
    int days = 10,
  }) async {
    try {
      final url =
          'https://api.bagas.website/api/ai/price-history?product_id=$productId&days=$days';
      print('🤖 [AI] GET $url');

      final response = await http
          .get(Uri.parse(url), headers: _buildHeaders())
          .timeout(_timeout);

      print('🤖 [AI] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true && result['data'] != null) {
          return ProductPriceHistory.fromJson(result['data']);
        } else {
          throw Exception(result['message'] ?? 'Failed to get price history');
        }
      } else {
        throw Exception('Failed to get price history: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [AI] Price history error: $e');
      rethrow;
    }
  }

  // ==================== SENTIMENT ANALYSIS ====================

  /// Analyze sentiment of a review text
  ///
  /// [text] - Review text to analyze (max 500 characters)
  /// Returns sentiment result with positive/negative classification
  static Future<SentimentResult> analyzeSentiment(String text) async {
    if (text.trim().isEmpty) {
      throw Exception('Text cannot be empty');
    }

    if (text.length > 500) {
      throw Exception('Text must be 500 characters or less');
    }

    try {
      final result = await _post('/analyze/sentiment', {'text': text.trim()});

      if (result['success'] == true && result['data'] != null) {
        return SentimentResult.fromJson(result['data']);
      } else {
        final error = result['error'];
        throw Exception(error?['message'] ?? 'Sentiment analysis failed');
      }
    } catch (e) {
      print('❌ [AI] Sentiment analysis error: $e');
      rethrow;
    }
  }

  /// Analyze sentiment of multiple reviews
  ///
  /// Returns list of sentiment results
  static Future<List<SentimentResult>> analyzeSentimentBatch(
    List<String> texts,
  ) async {
    final results = <SentimentResult>[];

    for (final text in texts) {
      try {
        final result = await analyzeSentiment(text);
        results.add(result);
      } catch (e) {
        // Add failed result
        results.add(
          SentimentResult(
            sentiment: 'Unknown',
            sentimentLabel: 'Tidak Diketahui',
            confidence: 0.0,
            rawScore: 0.0,
            emoji: '❓',
            textPreview: text.length > 50
                ? '${text.substring(0, 50)}...'
                : text,
            error: e.toString(),
          ),
        );
      }
    }

    return results;
  }

  // ==================== ANOMALY DETECTION ====================

  /// Detect if a transaction is anomalous (potential tengkulak)
  ///
  /// [transactionVolume] - Volume in kg per month
  /// [transactionFrequency] - Number of transactions per month
  /// Returns anomaly detection result
  static Future<AnomalyResult> detectAnomaly({
    required double transactionVolume,
    required double transactionFrequency,
  }) async {
    if (transactionVolume <= 0) {
      throw Exception('Transaction volume must be positive');
    }

    if (transactionFrequency <= 0) {
      throw Exception('Transaction frequency must be positive');
    }

    try {
      final result = await _post('/detect/anomaly', {
        'transaction_volume': transactionVolume,
        'transaction_frequency': transactionFrequency,
      });

      if (result['success'] == true && result['data'] != null) {
        return AnomalyResult.fromJson(result['data']);
      } else {
        final error = result['error'];
        throw Exception(error?['message'] ?? 'Anomaly detection failed');
      }
    } catch (e) {
      print('❌ [AI] Anomaly detection error: $e');
      rethrow;
    }
  }
}

// ==================== DATA MODELS ====================

/// Product Price History Result
class ProductPriceHistory {
  final int productId;
  final String productName;
  final double currentPrice;
  final String? imageUrl;
  final List<double> prices;
  final int days;
  final bool hasRealHistory;

  ProductPriceHistory({
    required this.productId,
    required this.productName,
    required this.currentPrice,
    this.imageUrl,
    required this.prices,
    required this.days,
    required this.hasRealHistory,
  });

  factory ProductPriceHistory.fromJson(Map<String, dynamic> json) {
    final product = json['product'] ?? {};
    final pricesList = json['prices'] as List<dynamic>? ?? [];

    return ProductPriceHistory(
      productId: (product['id'] as num?)?.toInt() ?? 0,
      productName: product['name'] ?? 'Unknown',
      currentPrice: (product['current_price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: product['image_url'],
      prices: pricesList.map((p) => (p as num).toDouble()).toList(),
      days: (json['days'] as num?)?.toInt() ?? 0,
      hasRealHistory: json['has_real_history'] ?? false,
    );
  }
}

/// Price Prediction Result
class PricePredictionResult {
  final double predictedPrice;
  final String currency;
  final double inputMin;
  final double inputMax;
  final double inputMean;
  final double inputLast;
  final double priceChange;
  final String trend;
  final int? productId;
  final String? productName;

  PricePredictionResult({
    required this.predictedPrice,
    required this.currency,
    required this.inputMin,
    required this.inputMax,
    required this.inputMean,
    required this.inputLast,
    required this.priceChange,
    required this.trend,
    this.productId,
    this.productName,
  });

  factory PricePredictionResult.fromJson(
    Map<String, dynamic> json, {
    int? productId,
    String? productName,
  }) {
    final inputPrices = json['input_prices'] ?? {};

    return PricePredictionResult(
      predictedPrice: (json['predicted_price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'IDR',
      inputMin: (inputPrices['min'] as num?)?.toDouble() ?? 0.0,
      inputMax: (inputPrices['max'] as num?)?.toDouble() ?? 0.0,
      inputMean: (inputPrices['mean'] as num?)?.toDouble() ?? 0.0,
      inputLast: (inputPrices['last'] as num?)?.toDouble() ?? 0.0,
      priceChange: (json['price_change_percent'] as num?)?.toDouble() ?? 0.0,
      trend: json['trend'] ?? 'stable',
      productId: productId,
      productName: productName,
    );
  }

  bool get isPriceIncreasing => trend == 'up';
  bool get isPriceDecreasing => trend == 'down';
  bool get isPriceStable => trend == 'stable';
  bool get hasProductInfo => productId != null && productName != null;

  String get priceChangeFormatted {
    final sign = priceChange >= 0 ? '+' : '';
    return '$sign${priceChange.toStringAsFixed(2)}%';
  }

  String get trendEmoji {
    switch (trend) {
      case 'up':
        return '📈';
      case 'down':
        return '📉';
      default:
        return '➡️';
    }
  }

  String get recommendation {
    final productPrefix = productName != null ? '$productName: ' : '';
    if (priceChange > 5) {
      return '${productPrefix}Harga diprediksi naik signifikan. Pertimbangkan untuk menaikkan harga jual.';
    } else if (priceChange > 0) {
      return '${productPrefix}Harga diprediksi naik sedikit. Harga saat ini masih kompetitif.';
    } else if (priceChange < -5) {
      return '${productPrefix}Harga diprediksi turun signifikan. Pertimbangkan promo atau diskon.';
    } else if (priceChange < 0) {
      return '${productPrefix}Harga diprediksi turun sedikit. Pantau persaingan pasar.';
    } else {
      return '${productPrefix}Harga diprediksi stabil. Pertahankan strategi harga saat ini.';
    }
  }

  @override
  String toString() {
    final productInfo = productName != null ? ' for $productName' : '';
    return 'PricePredictionResult(predicted: Rp $predictedPrice$productInfo, change: $priceChangeFormatted, trend: $trend)';
  }
}

/// Sentiment Analysis Result
class SentimentResult {
  final String sentiment;
  final String sentimentLabel;
  final double confidence;
  final double rawScore;
  final String emoji;
  final String textPreview;
  final String? error;

  SentimentResult({
    required this.sentiment,
    required this.sentimentLabel,
    required this.confidence,
    required this.rawScore,
    required this.emoji,
    required this.textPreview,
    this.error,
  });

  factory SentimentResult.fromJson(Map<String, dynamic> json) {
    return SentimentResult(
      sentiment: json['sentiment'] ?? 'Unknown',
      sentimentLabel: json['sentiment_label'] ?? 'Tidak Diketahui',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      rawScore: (json['raw_score'] as num?)?.toDouble() ?? 0.0,
      emoji: json['emoji'] ?? '❓',
      textPreview: json['text_preview'] ?? '',
    );
  }

  bool get isPositive => sentiment.toLowerCase() == 'positive';
  bool get isNegative => sentiment.toLowerCase() == 'negative';
  bool get hasError => error != null;

  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';

  @override
  String toString() {
    return 'SentimentResult($emoji $sentimentLabel, confidence: $confidencePercent)';
  }
}

/// Anomaly Detection Result
class AnomalyResult {
  final String status;
  final String statusLabel;
  final String riskLevel;
  final String riskLabel;
  final String recommendation;
  final double transactionVolume;
  final double transactionFrequency;
  final String emoji;

  AnomalyResult({
    required this.status,
    required this.statusLabel,
    required this.riskLevel,
    required this.riskLabel,
    required this.recommendation,
    required this.transactionVolume,
    required this.transactionFrequency,
    required this.emoji,
  });

  factory AnomalyResult.fromJson(Map<String, dynamic> json) {
    final details = json['transaction_details'] ?? {};

    return AnomalyResult(
      status: json['status'] ?? 'Unknown',
      statusLabel: json['status_label'] ?? 'Tidak Diketahui',
      riskLevel: json['risk_level'] ?? 'unknown',
      riskLabel: json['risk_label'] ?? 'Tidak Diketahui',
      recommendation: json['recommendation'] ?? '',
      transactionVolume: (details['volume_kg'] as num?)?.toDouble() ?? 0.0,
      transactionFrequency:
          (details['frequency_per_month'] as num?)?.toDouble() ?? 0.0,
      emoji: json['emoji'] ?? '❓',
    );
  }

  bool get isNormal => status.toLowerCase() == 'normal';
  bool get isAnomalous => status.toLowerCase() == 'anomaly';
  bool get isHighRisk => riskLevel.toLowerCase() == 'high';

  String get statusFormatted {
    if (isNormal) {
      return '✅ $statusLabel';
    } else {
      return '⚠️ $statusLabel';
    }
  }

  String get riskBadge {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return '🟢 $riskLabel';
      case 'medium':
        return '🟡 $riskLabel';
      case 'high':
        return '🔴 $riskLabel';
      default:
        return '⚪ $riskLabel';
    }
  }

  @override
  String toString() {
    return 'AnomalyResult($statusFormatted, risk: $riskLabel)';
  }
}
