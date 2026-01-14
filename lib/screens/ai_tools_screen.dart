import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rempah_nusantara/config/app_theme.dart';
import 'package:rempah_nusantara/services/ai_service.dart';

class AiToolsScreen extends StatefulWidget {
  const AiToolsScreen({super.key});

  @override
  State<AiToolsScreen> createState() => _AiToolsScreenState();
}

class _AiToolsScreenState extends State<AiToolsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isAiAvailable = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkAiAvailability();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAiAvailability() async {
    final available = await AiService.isAvailable();
    if (mounted) {
      setState(() => _isAiAvailable = available);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.psychology, size: 24),
            const SizedBox(width: 8),
            const Text('AI Tools'),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _isAiAvailable
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isAiAvailable ? Icons.check_circle : Icons.error,
                  size: 14,
                  color: _isAiAvailable ? Colors.greenAccent : Colors.redAccent,
                ),
                const SizedBox(width: 4),
                Text(
                  _isAiAvailable ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isAiAvailable
                        ? Colors.greenAccent
                        : Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.trending_up), text: 'Harga'),
            Tab(icon: Icon(Icons.sentiment_satisfied), text: 'Sentimen'),
            Tab(icon: Icon(Icons.security), text: 'Anomali'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _PricePredictionTab(),
          _SentimentAnalysisTab(),
          _AnomalyDetectionTab(),
        ],
      ),
    );
  }
}

// ==================== PRICE PREDICTION TAB ====================

class _PricePredictionTab extends StatefulWidget {
  const _PricePredictionTab();

  @override
  State<_PricePredictionTab> createState() => _PricePredictionTabState();
}

class _PricePredictionTabState extends State<_PricePredictionTab> {
  final List<TextEditingController> _priceControllers = List.generate(
    10,
    (_) => TextEditingController(),
  );
  bool _isLoading = false;
  PricePredictionResult? _result;
  String? _error;

  @override
  void dispose() {
    for (var controller in _priceControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _fillSampleData() {
    final samplePrices = [
      '25000',
      '26000',
      '25500',
      '27000',
      '26500',
      '28000',
      '27500',
      '29000',
      '28500',
      '30000',
    ];
    for (int i = 0; i < 10; i++) {
      _priceControllers[i].text = samplePrices[i];
    }
    setState(() {});
  }

  void _clearAll() {
    for (var controller in _priceControllers) {
      controller.clear();
    }
    setState(() {
      _result = null;
      _error = null;
    });
  }

  Future<void> _predictPrice() async {
    // Validate inputs
    final prices = <double>[];
    for (int i = 0; i < 10; i++) {
      final text = _priceControllers[i].text.trim();
      if (text.isEmpty) {
        setState(() => _error = 'Harga ke-${i + 1} tidak boleh kosong');
        return;
      }
      final price = double.tryParse(text);
      if (price == null || price <= 0) {
        setState(() => _error = 'Harga ke-${i + 1} harus berupa angka positif');
        return;
      }
      prices.add(price);
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final result = await AiService.predictPrice(prices);
      if (mounted) {
        setState(() {
          _result = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.secondary.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prediksi Harga LSTM',
                        style: AppTextStyles.subtitle1.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Masukkan 10 data harga historis untuk memprediksi harga selanjutnya',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _fillSampleData,
                  icon: const Icon(Icons.auto_fix_high, size: 18),
                  label: const Text('Isi Contoh'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _clearAll,
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Hapus Semua'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Price Inputs
          Text(
            'Data Harga Historis (Rp)',
            style: AppTextStyles.subtitle1.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 10,
            itemBuilder: (context, index) {
              return TextField(
                controller: _priceControllers[index],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Harga ${index + 1}',
                  prefixText: 'Rp ',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Predict Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _predictPrice,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.analytics),
              label: Text(_isLoading ? 'Memproses...' : 'Prediksi Harga'),
            ),
          ),

          const SizedBox(height: 20),

          // Error Message
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Result Card
          if (_result != null) _buildPriceResultCard(_result!),
        ],
      ),
    );
  }

  Widget _buildPriceResultCard(PricePredictionResult result) {
    final trendColor = result.isPriceIncreasing
        ? AppColors.success
        : result.isPriceDecreasing
        ? AppColors.error
        : AppColors.info;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: trendColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  result.trendEmoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Prediksi Harga', style: AppTextStyles.caption),
                    Text(
                      'Rp ${result.predictedPrice.toStringAsFixed(0)}',
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: trendColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  result.priceChangeFormatted,
                  style: AppTextStyles.subtitle2.copyWith(
                    color: trendColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Statistics
          Row(
            children: [
              _buildStatItem('Min', 'Rp ${result.inputMin.toStringAsFixed(0)}'),
              _buildStatItem('Max', 'Rp ${result.inputMax.toStringAsFixed(0)}'),
              _buildStatItem(
                'Rata-rata',
                'Rp ${result.inputMean.toStringAsFixed(0)}',
              ),
              _buildStatItem(
                'Terakhir',
                'Rp ${result.inputLast.toStringAsFixed(0)}',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Recommendation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.info,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.recommendation,
                    style: AppTextStyles.body2.copyWith(color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ==================== SENTIMENT ANALYSIS TAB ====================

class _SentimentAnalysisTab extends StatefulWidget {
  const _SentimentAnalysisTab();

  @override
  State<_SentimentAnalysisTab> createState() => _SentimentAnalysisTabState();
}

class _SentimentAnalysisTabState extends State<_SentimentAnalysisTab> {
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;
  SentimentResult? _result;
  String? _error;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _fillSamplePositive() {
    _textController.text =
        'Rempahnya sangat bagus, wangi dan berkualitas tinggi. Pengiriman cepat dan packing aman. Pasti order lagi!';
    setState(() {});
  }

  void _fillSampleNegative() {
    _textController.text =
        'Kualitas rempah buruk, sudah tidak segar dan jelek.';
    setState(() {});
  }

  Future<void> _analyzeSentiment() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Teks tidak boleh kosong');
      return;
    }

    if (text.length > 500) {
      setState(() => _error = 'Teks maksimal 500 karakter');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final result = await AiService.analyzeSentiment(text);
      if (mounted) {
        setState(() {
          _result = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.secondary.withOpacity(0.1),
                  AppColors.primary.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.sentiment_satisfied_alt,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Analisis Sentimen CNN-LSTM',
                        style: AppTextStyles.subtitle1.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Analisis ulasan untuk mengetahui sentimen positif atau negatif',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Sample Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _fillSamplePositive,
                  icon: const Icon(Icons.sentiment_very_satisfied, size: 18),
                  label: const Text('Contoh Positif'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                    side: const BorderSide(color: AppColors.success),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _fillSampleNegative,
                  icon: const Icon(Icons.sentiment_very_dissatisfied, size: 18),
                  label: const Text('Contoh Negatif'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Text Input
          Text(
            'Teks Ulasan',
            style: AppTextStyles.subtitle1.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _textController,
            maxLines: 5,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'Masukkan ulasan produk...',
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: 16),

          // Analyze Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _analyzeSentiment,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.psychology),
              label: Text(_isLoading ? 'Menganalisis...' : 'Analisis Sentimen'),
            ),
          ),

          const SizedBox(height: 20),

          // Error Message
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Result Card
          if (_result != null) _buildSentimentResultCard(_result!),
        ],
      ),
    );
  }

  Widget _buildSentimentResultCard(SentimentResult result) {
    final isPositive = result.isPositive;
    final color = isPositive ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Emoji & Sentiment
          Text(result.emoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          Text(
            result.sentimentLabel,
            style: AppTextStyles.heading2.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Confidence
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Confidence: ${result.confidencePercent}',
              style: AppTextStyles.subtitle2.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Skor', style: AppTextStyles.caption),
                  Text(
                    '${(result.rawScore * 100).toStringAsFixed(1)}%',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: result.rawScore,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('😞 Negatif', style: AppTextStyles.caption),
                  Text('Positif 😊', style: AppTextStyles.caption),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Preview Text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Teks yang dianalisis:', style: AppTextStyles.caption),
                const SizedBox(height: 4),
                Text(
                  '"${result.textPreview}"',
                  style: AppTextStyles.body2.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== ANOMALY DETECTION TAB ====================

class _AnomalyDetectionTab extends StatefulWidget {
  const _AnomalyDetectionTab();

  @override
  State<_AnomalyDetectionTab> createState() => _AnomalyDetectionTabState();
}

class _AnomalyDetectionTabState extends State<_AnomalyDetectionTab> {
  final TextEditingController _volumeController = TextEditingController();
  final TextEditingController _frequencyController = TextEditingController();
  bool _isLoading = false;
  AnomalyResult? _result;
  String? _error;

  @override
  void dispose() {
    _volumeController.dispose();
    _frequencyController.dispose();
    super.dispose();
  }

  void _fillSampleNormal() {
    _volumeController.text = '50';
    _frequencyController.text = '3';
    setState(() {});
  }

  void _fillSampleAnomaly() {
    _volumeController.text = '500';
    _frequencyController.text = '20';
    setState(() {});
  }

  Future<void> _detectAnomaly() async {
    final volumeText = _volumeController.text.trim();
    final frequencyText = _frequencyController.text.trim();

    if (volumeText.isEmpty) {
      setState(() => _error = 'Volume transaksi tidak boleh kosong');
      return;
    }

    if (frequencyText.isEmpty) {
      setState(() => _error = 'Frekuensi transaksi tidak boleh kosong');
      return;
    }

    final volume = double.tryParse(volumeText);
    final frequency = double.tryParse(frequencyText);

    if (volume == null || volume <= 0) {
      setState(() => _error = 'Volume harus berupa angka positif');
      return;
    }

    if (frequency == null || frequency <= 0) {
      setState(() => _error = 'Frekuensi harus berupa angka positif');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final result = await AiService.detectAnomaly(
        transactionVolume: volume,
        transactionFrequency: frequency,
      );
      if (mounted) {
        setState(() {
          _result = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.info.withOpacity(0.1),
                  AppColors.primary.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.security, color: AppColors.info),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deteksi Anomali Isolation Forest',
                        style: AppTextStyles.subtitle1.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Deteksi pola transaksi mencurigakan (potensi tengkulak)',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Sample Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _fillSampleNormal,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Contoh Normal'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                    side: const BorderSide(color: AppColors.success),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _fillSampleAnomaly,
                  icon: const Icon(Icons.warning_amber, size: 18),
                  label: const Text('Contoh Anomali'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.warning,
                    side: const BorderSide(color: AppColors.warning),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Volume Input
          Text(
            'Volume Transaksi (kg/bulan)',
            style: AppTextStyles.subtitle1.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _volumeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Contoh: 50',
              suffixText: 'kg',
            ),
          ),

          const SizedBox(height: 16),

          // Frequency Input
          Text(
            'Frekuensi Transaksi (per bulan)',
            style: AppTextStyles.subtitle1.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _frequencyController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Contoh: 3',
              suffixText: 'transaksi',
            ),
          ),

          const SizedBox(height: 20),

          // Detect Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _detectAnomaly,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search),
              label: Text(_isLoading ? 'Mendeteksi...' : 'Deteksi Anomali'),
            ),
          ),

          const SizedBox(height: 20),

          // Error Message
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Result Card
          if (_result != null) _buildAnomalyResultCard(_result!),
        ],
      ),
    );
  }

  Widget _buildAnomalyResultCard(AnomalyResult result) {
    final isNormal = result.isNormal;
    final color = isNormal ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status Icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(result.emoji, style: const TextStyle(fontSize: 48)),
          ),
          const SizedBox(height: 16),

          // Status Label
          Text(
            result.statusLabel,
            style: AppTextStyles.heading2.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Risk Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              result.riskBadge,
              style: AppTextStyles.subtitle2.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),

          // Transaction Details
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.inventory_2_outlined,
                  label: 'Volume',
                  value: '${result.transactionVolume.toStringAsFixed(1)} kg',
                ),
              ),
              Container(width: 1, height: 50, color: AppColors.border),
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.repeat,
                  label: 'Frekuensi',
                  value:
                      '${result.transactionFrequency.toStringAsFixed(0)}x/bulan',
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Recommendation
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isNormal ? Icons.check_circle : Icons.warning_amber,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.recommendation,
                    style: AppTextStyles.body2.copyWith(color: color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.iconGrey, size: 24),
        const SizedBox(height: 8),
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
