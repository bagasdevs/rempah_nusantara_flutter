import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rempah_nusantara/config/app_theme.dart';
import 'package:rempah_nusantara/services/payment_service.dart';
import 'package:rempah_nusantara/services/api_service.dart';
import 'package:rempah_nusantara/widgets/bottom_nav_bar.dart';

class OrderStatusScreen extends StatefulWidget {
  final int orderId;

  const OrderStatusScreen({super.key, required this.orderId});

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen>
    with WidgetsBindingObserver {
  Timer? _pollingTimer;
  Timer? _redirectTimer;
  Map<String, dynamic>? _orderData;
  bool _isLoading = true;
  String _paymentStatus = 'pending';
  String _orderStatus = 'pending_payment';
  int _pollCount = 0;
  final int _maxPolls = 30;
  int _redirectCountdown = 3;
  bool _isRedirecting = false;

  @override
  void initState() {
    super.initState();
    // Register observer to detect when app comes back from payment page
    WidgetsBinding.instance.addObserver(this);
    _loadOrderStatus();
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    _redirectTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // When app resumes (user comes back from Midtrans payment page)
    if (state == AppLifecycleState.resumed) {
      print('🔄 [OrderStatusScreen] App resumed - refreshing payment status');
      _handleAppResumed();
    }
  }

  /// Called when app resumes from background (e.g., after Midtrans payment)
  Future<void> _handleAppResumed() async {
    // Only refresh if payment is still pending
    if (_paymentStatus == 'pending' && mounted) {
      // Show loading indicator
      setState(() => _isLoading = true);

      // Small delay to allow Midtrans webhook to process
      await Future.delayed(const Duration(milliseconds: 500));

      // Refresh the order status
      await _loadOrderStatus();

      // Show a snackbar to indicate refresh
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.sync, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Status pembayaran diperbarui'),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
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
          _startRedirectCountdown();
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
            Expanded(
              child: Text(
                'Pembayaran berhasil! Mengalihkan ke halaman pesanan...',
              ),
            ),
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

  void _cancelRedirect() {
    _redirectTimer?.cancel();
    setState(() {
      _isRedirecting = false;
      _redirectCountdown = 3;
    });
  }

  void _startRedirectCountdown() {
    if (_isRedirecting) return; // Prevent multiple timers

    setState(() {
      _isRedirecting = true;
      _redirectCountdown = 3;
    });

    _redirectTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _redirectCountdown--;
      });

      if (_redirectCountdown <= 0) {
        timer.cancel();
        if (mounted) {
          context.go('/orders');
        }
      }
    });
  }

  Future<void> _manualRefresh() async {
    setState(() => _isLoading = true);
    await _loadOrderStatus();

    // Show feedback
    if (mounted) {
      final statusText = _getStatusText(_paymentStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status: $statusText'),
          duration: Duration(seconds: 2),
        ),
      );
    }
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
    final isPaid = _paymentStatus == 'paid' || _paymentStatus == 'settlement';

    return Card(
      elevation: isPaid ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isPaid
            ? BorderSide(color: Colors.green.shade300, width: 2)
            : BorderSide.none,
      ),
      child: Container(
        decoration: isPaid
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.green.shade50, Colors.white],
                ),
              )
            : null,
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            // Success animation container
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor.withOpacity(0.15),
                border: Border.all(
                  color: statusColor.withOpacity(0.3),
                  width: 3,
                ),
              ),
              child: Icon(statusIcon, size: 56, color: statusColor),
            ),
            SizedBox(height: 20),
            Text(
              statusText,
              style: AppTextStyles.heading2.copyWith(
                color: statusColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Status Pembayaran',
                style: AppTextStyles.body2.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Success message for paid status
            if (isPaid) ...[
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.celebration,
                      color: Colors.green.shade700,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Terima kasih!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.green.shade800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Pesanan Anda sedang diproses',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Countdown timer when redirecting
            if (_isRedirecting) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              Colors.green.shade700,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Mengalihkan ke Pesanan dalam $_redirectCountdown detik...',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _cancelRedirect,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green.shade700,
                          side: BorderSide(color: Colors.green.shade700),
                          padding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Text('Tetap di Halaman Ini'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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

    final isPaid = _paymentStatus == 'paid' || _paymentStatus == 'settlement';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: AppColors.primary, size: 22),
                SizedBox(width: 8),
                Text('Detail Pesanan', style: AppTextStyles.heading3),
              ],
            ),
            SizedBox(height: 20),
            _buildDetailRow(
              'Total Pembayaran',
              'Rp ${_formatCurrency(_orderData?['total_price'] ?? 0)}',
              isHighlighted: true,
            ),
            _buildDetailRow(
              'Biaya Pengiriman',
              'Rp ${_formatCurrency(_orderData?['shipping_cost'] ?? 0)}',
            ),
            Divider(height: 24),
            _buildDetailRow(
              'Status Pesanan',
              _formatOrderStatus(_orderStatus),
              valueColor: isPaid ? Colors.green : null,
            ),
            if (_orderData?['created_at'] != null)
              _buildDetailRow(
                'Tanggal Pesanan',
                _formatDate(_orderData!['created_at']),
              ),
            if (_orderData?['paid_at'] != null && isPaid)
              _buildDetailRow(
                'Tanggal Pembayaran',
                _formatDate(_orderData!['paid_at']),
                valueColor: Colors.green,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isHighlighted = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: AppTextStyles.body1.copyWith(
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
              fontSize: isHighlighted ? 16 : 14,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Prominent refresh button when payment is pending
        if (_paymentStatus == 'pending') ...[
          Container(
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.amber.shade700,
                  size: 32,
                ),
                SizedBox(height: 8),
                Text(
                  'Sudah selesai bayar?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.amber.shade900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tekan tombol di bawah untuk memperbarui status pembayaran',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.amber.shade800),
                ),
                SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _manualRefresh,
                  icon: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(Icons.refresh),
                  label: Text(
                    _isLoading ? 'Memperbarui...' : 'Cek Status Pembayaran',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_paymentStatus == 'paid' || _paymentStatus == 'settlement') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/orders'),
              icon: Icon(Icons.list_alt),
              label: Text('Lihat Semua Pesanan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/'),
              icon: Icon(Icons.home_outlined),
              label: Text('Kembali ke Beranda'),
              style: OutlinedButton.styleFrom(
                minimumSize: Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
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
