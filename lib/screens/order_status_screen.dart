import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/config/app_theme.dart';
import 'package:myapp/services/payment_service.dart';
import 'package:myapp/services/api_service.dart';
import 'package:myapp/widgets/bottom_nav_bar.dart';

class OrderStatusScreen extends StatefulWidget {
  final int orderId;

  const OrderStatusScreen({super.key, required this.orderId});

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  Timer? _pollingTimer;
  Map<String, dynamic>? _orderData;
  bool _isLoading = true;
  String _paymentStatus = 'pending';
  String _orderStatus = 'pending_payment';
  int _pollCount = 0;
  final int _maxPolls = 30;

  @override
  void initState() {
    super.initState();
    _loadOrderStatus();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrderStatus() async {
    try {
      final response = await ApiService.checkPaymentStatus(widget.orderId);

      if (mounted && response['success'] == true && response['data'] != null) {
        setState(() {
          _orderData = response['data'];
          _paymentStatus = _orderData?['payment_status'] ?? 'pending';
          _orderStatus = _orderData?['status'] ?? 'pending_payment';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading order status: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startPolling() {
    _pollingTimer = PaymentService.startPollingOrderStatus(widget.orderId, (
      order,
    ) {
      if (mounted) {
        setState(() {
          _orderData = order;
          _paymentStatus = order['payment_status'] ?? 'pending';
          _orderStatus = order['status'] ?? 'pending_payment';
          _pollCount++;
        });

        // Show notification when payment is complete
        if (_paymentStatus == 'paid' || _paymentStatus == 'settlement') {
          _showSuccessNotification();
        } else if (_paymentStatus == 'failed' ||
            _paymentStatus == 'expired' ||
            _paymentStatus == 'cancelled') {
          _showFailureNotification();
        }
      }
    }, maxPolls: _maxPolls);
  }

  void _showSuccessNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Pembayaran berhasil!'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showFailureNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Text('Pembayaran gagal atau dibatalkan'),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _manualRefresh() async {
    setState(() => _isLoading = true);
    await _loadOrderStatus();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid':
      case 'settlement':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
      case 'cancelled':
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'paid':
      case 'settlement':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'failed':
      case 'cancelled':
      case 'expired':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'paid':
      case 'settlement':
        return 'Pembayaran Berhasil';
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'failed':
        return 'Pembayaran Gagal';
      case 'cancelled':
        return 'Pembayaran Dibatalkan';
      case 'expired':
        return 'Pembayaran Kadaluarsa';
      default:
        return 'Status Tidak Diketahui';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Status Pesanan'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : _manualRefresh,
            tooltip: 'Refresh Status',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _manualRefresh,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOrderNumberCard(),
                    SizedBox(height: 16),
                    _buildPaymentStatusCard(),
                    SizedBox(height: 16),
                    _buildPollingInfo(),
                    SizedBox(height: 16),
                    _buildOrderDetails(),
                    SizedBox(height: 24),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const BottomNavBar(currentRoute: '/orders'),
    );
  }

  Widget _buildOrderNumberCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.receipt_long, size: 32, color: AppColors.primary),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nomor Pesanan',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _orderData?['order_number'] ?? 'ORD-${widget.orderId}',
                    style: AppTextStyles.heading3,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStatusCard() {
    final statusColor = _getStatusColor(_paymentStatus);
    final statusIcon = _getStatusIcon(_paymentStatus);
    final statusText = _getStatusText(_paymentStatus);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(statusIcon, size: 64, color: statusColor),
            SizedBox(height: 12),
            Text(
              statusText,
              style: AppTextStyles.heading2.copyWith(color: statusColor),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Status Pembayaran',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (_paymentStatus == 'pending') ...[
              SizedBox(height: 16),
              LinearProgressIndicator(
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
              SizedBox(height: 8),
              Text(
                'Menunggu konfirmasi pembayaran...',
                style: AppTextStyles.body2,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPollingInfo() {
    if (_paymentStatus == 'pending') {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Auto-refresh aktif',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Status akan diperbarui otomatis setiap 10 detik (${_pollCount}/$_maxPolls)',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.blue.shade700),
                ),
              ),
          ],
        ),
      );
    }
    return SizedBox.shrink();
  }

  Widget _buildOrderDetails() {
    if (_orderData == null) return SizedBox.shrink();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detail Pesanan', style: AppTextStyles.heading3),
            SizedBox(height: 16),
            _buildDetailRow(
              'Total Pembayaran',
              'Rp ${_formatCurrency(_orderData?['total_price'] ?? 0)}',
            ),
            _buildDetailRow(
              'Biaya Pengiriman',
              'Rp ${_formatCurrency(_orderData?['shipping_cost'] ?? 0)}',
            ),
            Divider(height: 24),
            _buildDetailRow('Status Pesanan', _formatOrderStatus(_orderStatus)),
            if (_orderData?['created_at'] != null)
              _buildDetailRow(
                'Tanggal Pesanan',
                _formatDate(_orderData!['created_at']),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body2),
          Text(
            value,
            style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_paymentStatus == 'paid' || _paymentStatus == 'settlement')
          ElevatedButton(
            onPressed: () => context.go('/orders'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 48),
            ),
            child: Text('Lihat Semua Pesanan'),
          ),
        if (_paymentStatus == 'pending') ...[
          ElevatedButton(
            onPressed: () => context.go('/orders'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 48),
            ),
            child: Text('Lihat Pesanan Saya'),
          ),
          SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.go('/'),
            style: OutlinedButton.styleFrom(
              minimumSize: Size(double.infinity, 48),
            ),
            child: Text('Kembali ke Beranda'),
          ),
        ],
        if (_paymentStatus == 'failed' ||
            _paymentStatus == 'cancelled' ||
            _paymentStatus == 'expired') ...[
          ElevatedButton(
            onPressed: () => context.go('/'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 48),
            ),
            child: Text('Belanja Lagi'),
          ),
          SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.go('/orders'),
            style: OutlinedButton.styleFrom(
              minimumSize: Size(double.infinity, 48),
            ),
            child: Text('Lihat Pesanan Saya'),
          ),
        ],
      ],
    );
  }

  String _formatCurrency(dynamic amount) {
    final value = (amount is String) ? double.tryParse(amount) ?? 0 : amount;
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  String _formatOrderStatus(String status) {
    switch (status) {
      case 'pending_payment':
        return 'Menunggu Pembayaran';
      case 'processing':
        return 'Diproses';
      case 'shipped':
        return 'Dikirim';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}
