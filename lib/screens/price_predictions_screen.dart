import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rempah_nusantara/config/app_theme.dart';
import 'package:rempah_nusantara/services/api_service.dart';

class PricePredictionsScreen extends StatefulWidget {
  const PricePredictionsScreen({super.key});

  @override
  State<PricePredictionsScreen> createState() => _PricePredictionsScreenState();
}

class _PricePredictionsScreenState extends State<PricePredictionsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _predictions = [];
  String? _errorMessage;
  String? _selectedSpiceType;

  final List<String> _spiceTypes = [
    'Semua',
    'Jahe Merah',
    'Jahe Emprit',
    'Kunyit',
    'Lengkuas',
    'Lada Hitam',
    'Lada Putih',
    'Cengkeh',
    'Kayu Manis',
    'Pala',
    'Kemiri',
  ];

  @override
  void initState() {
    super.initState();
    _fetchPredictions();
  }

  Future<void> _fetchPredictions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final predictions = await ApiService.getPricePredictions(
        spiceType: _selectedSpiceType == 'Semua' ? null : _selectedSpiceType,
        limit: 20,
      );

      setState(() {
        _predictions = predictions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
          color: AppColors.textPrimary,
        ),
        title: Text(
          'Prediksi Harga',
          style: AppTextStyles.heading3.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPredictions,
            color: AppColors.textPrimary,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _errorMessage != null
                ? _buildErrorState()
                : _predictions.isEmpty
                ? _buildEmptyState()
                : _buildPredictionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Jenis Rempah',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _spiceTypes.length,
              itemBuilder: (context, index) {
                final spice = _spiceTypes[index];
                final isSelected =
                    _selectedSpiceType == spice ||
                    (_selectedSpiceType == null && spice == 'Semua');

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(spice),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedSpiceType = spice == 'Semua' ? null : spice;
                      });
                      _fetchPredictions();
                    },
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionsList() {
    return RefreshIndicator(
      onRefresh: _fetchPredictions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _predictions.length,
        itemBuilder: (context, index) {
          final prediction = _predictions[index];
          return _buildPredictionCard(prediction);
        },
      ),
    );
  }

  Widget _buildPredictionCard(Map<String, dynamic> prediction) {
    final spiceType = prediction['spice_type'] ?? 'Unknown';
    final currentPrice = (prediction['current_price'] as num?)?.toDouble() ?? 0;
    final predictedPrice =
        (prediction['predicted_price'] as num?)?.toDouble() ?? 0;
    final changePercent =
        (prediction['price_change_percent'] as num?)?.toDouble() ?? 0;
    final trend = prediction['trend'] ?? 'stable';
    final confidence = (prediction['ai_confidence'] as num?)?.toDouble() ?? 0.5;
    final targetDate = prediction['target_date'] ?? '';
    final factors = prediction['factors'] as Map<String, dynamic>?;
    final factorsList = factors?['factors'] as List<dynamic>? ?? [];

    Color trendColor;
    IconData trendIcon;
    String trendText;

    switch (trend) {
      case 'up':
        trendColor = Colors.red;
        trendIcon = Icons.trending_up;
        trendText = 'Naik';
        break;
      case 'down':
        trendColor = Colors.green;
        trendIcon = Icons.trending_down;
        trendText = 'Turun';
        break;
      default:
        trendColor = Colors.orange;
        trendIcon = Icons.trending_flat;
        trendText = 'Stabil';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(spiceType, style: AppTextStyles.heading4)),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: trendColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(trendIcon, size: 16, color: trendColor),
                      const SizedBox(width: 4),
                      Text(
                        '$trendText ${changePercent.abs().toStringAsFixed(1)}%',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: trendColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPriceColumn(
                    'Harga Saat Ini',
                    currentPrice,
                    AppColors.textSecondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.arrow_forward, color: trendColor, size: 24),
                ),
                Expanded(
                  child: _buildPriceColumn(
                    'Prediksi ($targetDate)',
                    predictedPrice,
                    trendColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Confidence: ${(confidence * 100).toStringAsFixed(0)}%',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: confidence,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        confidence >= 0.8
                            ? Colors.green
                            : confidence >= 0.6
                            ? Colors.orange
                            : Colors.red,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ),
              ],
            ),
            if (factorsList.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Faktor Penyebab:',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              ...factorsList
                  .take(3)
                  .map(
                    (factor) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 6,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              factor.toString(),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceColumn(String label, double price, Color priceColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Rp ${_formatPrice(price)}/kg',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: priceColor,
          ),
        ),
      ],
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      return price
          .toStringAsFixed(0)
          .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]}.',
          );
    }
    return price.toStringAsFixed(0);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up_outlined,
              size: 80,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Prediksi',
              style: AppTextStyles.heading4.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Prediksi harga rempah akan ditampilkan di sini',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Terjadi Kesalahan',
              style: AppTextStyles.heading4.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Gagal memuat prediksi harga',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchPredictions,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
