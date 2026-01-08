import 'api_service.dart';

/// AI Service for Rempah Nusantara
///
/// Provides access to AI-powered features:
/// - Price Prediction (LSTM)
/// - Sentiment Analysis (CNN-LSTM)
/// - Anomaly Detection (Isolation Forest)
class AiService {
  // ==================== PRICE PREDICTION ====================

  /// Predict optimal price based on 10 historical prices
  ///
  /// [historicalPrices] - List of exactly 10 historical prices
  /// Returns prediction result with predicted price and analysis
  static Future<PricePredictionResult> predictPrice(
    List<double> historicalPrices,
  ) async {
    if (historicalPrices.length != 10) {
      throw Exception('Exactly 10 historical prices are required');
    }

    if (historicalPrices.any((price) => price <= 0)) {
      throw Exception('All prices must be positive');
    }

    try {
      final result = await ApiService.post('/api/ai/price', {
        'data': historicalPrices,
      });

      if (result['success'] == true && result['data'] != null) {
        return PricePredictionResult.fromJson(result['data']);
      } else {
        throw Exception(result['message'] ?? 'Price prediction failed');
      }
    } catch (e) {
      print('❌ [AI] Price prediction error: $e');
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
      final result = await ApiService.post('/api/ai/sentiment', {
        'text': text.trim(),
      });

      if (result['success'] == true && result['data'] != null) {
        return SentimentResult.fromJson(result['data']);
      } else {
        throw Exception(result['message'] ?? 'Sentiment analysis failed');
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
      final result = await ApiService.post('/api/ai/anomaly', {
        'transaction_volume': transactionVolume,
        'transaction_frequency': transactionFrequency,
      });

      if (result['success'] == true && result['data'] != null) {
        return AnomalyResult.fromJson(result['data']);
      } else {
        throw Exception(result['message'] ?? 'Anomaly detection failed');
      }
    } catch (e) {
      print('❌ [AI] Anomaly detection error: $e');
      rethrow;
    }
  }

  /// Check if a buyer's transaction history is suspicious
  ///
  /// [buyerId] - User ID of the buyer
  /// Returns anomaly detection based on historical transactions
  static Future<AnomalyResult> checkBuyerHistory(String buyerId) async {
    // This would typically fetch buyer's transaction history first
    // For now, we'll need to implement this with actual data

    try {
      final result = await ApiService.get('/api/ai/anomaly/buyer?id=$buyerId');

      if (result['success'] == true && result['data'] != null) {
        return AnomalyResult.fromJson(result['data']);
      } else {
        throw Exception(result['message'] ?? 'Buyer check failed');
      }
    } catch (e) {
      print('❌ [AI] Buyer history check error: $e');
      rethrow;
    }
  }
}

// ==================== DATA MODELS ====================

/// Price Prediction Result
class PricePredictionResult {
  final double predictedPrice;
  final String currency;
  final double inputMin;
  final double inputMax;
  final double inputMean;
  final double inputLast;
  final double priceChange;

  PricePredictionResult({
    required this.predictedPrice,
    required this.currency,
    required this.inputMin,
    required this.inputMax,
    required this.inputMean,
    required this.inputLast,
    required this.priceChange,
  });

  factory PricePredictionResult.fromJson(Map<String, dynamic> json) {
    final inputPrices = json['input_prices'] ?? {};

    return PricePredictionResult(
      predictedPrice: (json['predicted_price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'IDR',
      inputMin: (inputPrices['min'] as num?)?.toDouble() ?? 0.0,
      inputMax: (inputPrices['max'] as num?)?.toDouble() ?? 0.0,
      inputMean: (inputPrices['mean'] as num?)?.toDouble() ?? 0.0,
      inputLast: (inputPrices['last'] as num?)?.toDouble() ?? 0.0,
      priceChange: (json['price_change'] as num?)?.toDouble() ?? 0.0,
    );
  }

  bool get isPriceIncreasing => priceChange > 0;
  bool get isPriceDecreasing => priceChange < 0;
  bool get isPriceStable => priceChange.abs() < 1.0;

  String get priceChangeFormatted {
    final sign = priceChange >= 0 ? '+' : '';
    return '$sign${priceChange.toStringAsFixed(2)}%';
  }

  String get recommendation {
    if (priceChange > 5) {
      return 'Harga diprediksi naik signifikan. Pertimbangkan untuk menaikkan harga jual.';
    } else if (priceChange > 0) {
      return 'Harga diprediksi naik sedikit. Harga saat ini masih kompetitif.';
    } else if (priceChange < -5) {
      return 'Harga diprediksi turun signifikan. Pertimbangkan promo atau diskon.';
    } else if (priceChange < 0) {
      return 'Harga diprediksi turun sedikit. Pantau persaingan pasar.';
    } else {
      return 'Harga diprediksi stabil. Pertahankan strategi harga saat ini.';
    }
  }

  @override
  String toString() {
    return 'PricePredictionResult(predicted: Rp $predictedPrice, change: $priceChangeFormatted)';
  }
}

/// Sentiment Analysis Result
class SentimentResult {
  final String sentiment;
  final double confidence;
  final double rawScore;
  final String emoji;
  final String textPreview;
  final String? error;

  SentimentResult({
    required this.sentiment,
    required this.confidence,
    required this.rawScore,
    required this.emoji,
    required this.textPreview,
    this.error,
  });

  factory SentimentResult.fromJson(Map<String, dynamic> json) {
    return SentimentResult(
      sentiment: json['sentiment'] ?? 'Unknown',
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
    return 'SentimentResult($emoji $sentiment, confidence: $confidencePercent)';
  }
}

/// Anomaly Detection Result
class AnomalyResult {
  final String status;
  final String riskLevel;
  final String recommendation;
  final double transactionVolume;
  final double transactionFrequency;
  final String emoji;

  AnomalyResult({
    required this.status,
    required this.riskLevel,
    required this.recommendation,
    required this.transactionVolume,
    required this.transactionFrequency,
    required this.emoji,
  });

  factory AnomalyResult.fromJson(Map<String, dynamic> json) {
    final details = json['transaction_details'] ?? {};

    return AnomalyResult(
      status: json['status'] ?? 'Unknown',
      riskLevel: json['risk_level'] ?? 'unknown',
      recommendation: json['recommendation'] ?? '',
      transactionVolume: (details['volume_kg'] as num?)?.toDouble() ?? 0.0,
      transactionFrequency:
          (details['frequency_per_month'] as num?)?.toDouble() ?? 0.0,
      emoji: json['emoji'] ?? '❓',
    );
  }

  bool get isNormal => status.toLowerCase() == 'normal';
  bool get isAnomalous => status.toLowerCase() == 'anomalous';
  bool get isHighRisk => riskLevel.toLowerCase() == 'high';

  String get statusFormatted {
    if (isNormal) {
      return '✅ Normal';
    } else {
      return '⚠️ Mencurigakan';
    }
  }

  String get riskBadge {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return '🟢 Risiko Rendah';
      case 'medium':
        return '🟡 Risiko Sedang';
      case 'high':
        return '🔴 Risiko Tinggi';
      default:
        return '⚪ Tidak Diketahui';
    }
  }

  @override
  String toString() {
    return 'AnomalyResult($statusFormatted, risk: $riskLevel)';
  }
}
