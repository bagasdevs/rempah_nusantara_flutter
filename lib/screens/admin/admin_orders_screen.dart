import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _orders = [];
  Map<String, dynamic> _pagination = {};
  Map<String, dynamic> _stats = {};

  // Filters
  String? _selectedStatus;
  String? _selectedPaymentStatus;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final _dateFormat = DateFormat('dd MMM yyyy HH:mm', 'id_ID');

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders({int offset = 0}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ApiService.getAdminOrders(
        limit: 20,
        offset: offset,
        status: _selectedStatus,
        paymentStatus: _selectedPaymentStatus,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      setState(() {
        _orders = result['orders'];
        _pagination = result['pagination'];
        _stats = result['stats'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateOrderStatus(int orderId, String status) async {
    try {
      await ApiService.updateAdminOrder(orderId: orderId, status: status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status pesanan diperbarui ke ${_formatStatus(status)}',
          ),
          backgroundColor: Colors.green,
        ),
      );
      _loadOrders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// Update payment status for an order (used by admin when manually updating payment)
  // ignore: unused_element
  Future<void> _updatePaymentStatus(int orderId, String paymentStatus) async {
    try {
      await ApiService.updateAdminOrder(
        orderId: orderId,
        paymentStatus: paymentStatus,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status pembayaran diperbarui'),
          backgroundColor: Colors.green,
        ),
      );
      _loadOrders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _cancelOrder(int orderId, String orderNumber) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Batalkan Pesanan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Batalkan pesanan #$orderNumber?'),
            SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Alasan pembatalan (opsional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Batalkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.cancelAdminOrder(
          orderId,
          reason: reasonController.text.isNotEmpty
              ? reasonController.text
              : null,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pesanan berhasil dibatalkan'),
            backgroundColor: Colors.green,
          ),
        );
        _loadOrders();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membatalkan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showStatusDialog(int orderId, String currentStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ubah Status Pesanan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusOption(
              orderId,
              'processing',
              'Diproses',
              Icons.hourglass_top,
              Colors.blue,
              currentStatus,
            ),
            _buildStatusOption(
              orderId,
              'shipped',
              'Dikirim',
              Icons.local_shipping,
              Colors.indigo,
              currentStatus,
            ),
            _buildStatusOption(
              orderId,
              'delivered',
              'Terkirim',
              Icons.check_circle,
              Colors.teal,
              currentStatus,
            ),
            _buildStatusOption(
              orderId,
              'completed',
              'Selesai',
              Icons.done_all,
              Colors.green,
              currentStatus,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(
    int orderId,
    String status,
    String label,
    IconData icon,
    Color color,
    String currentStatus,
  ) {
    final isSelected = currentStatus == status;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      selected: isSelected,
      trailing: isSelected ? Icon(Icons.check, color: color) : null,
      onTap: () {
        Navigator.pop(context);
        if (!isSelected) {
          _updateOrderStatus(orderId, status);
        }
      },
    );
  }

  void _showTrackingDialog(int orderId) {
    final trackingController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Input Nomor Resi'),
        content: TextField(
          controller: trackingController,
          decoration: InputDecoration(
            labelText: 'Nomor Resi',
            border: OutlineInputBorder(),
            hintText: 'Contoh: JNE12345678',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (trackingController.text.isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Masukkan nomor resi')));
                return;
              }
              Navigator.pop(context);
              try {
                await ApiService.updateAdminOrder(
                  orderId: orderId,
                  trackingNumber: trackingController.text,
                  status: 'shipped',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Nomor resi berhasil disimpan'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadOrders();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
            child: Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Pesanan'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: () => _loadOrders()),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          if (_stats.isNotEmpty) _buildStatsBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.grey[100],
      padding: EdgeInsets.all(12),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari nomor pesanan...',
              prefixIcon: Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                        _loadOrders();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onSubmitted: (value) {
              setState(() {
                _searchQuery = value;
              });
              _loadOrders();
            },
          ),
          SizedBox(height: 12),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Semua',
                  selected: _selectedStatus == null,
                  onTap: () {
                    setState(() {
                      _selectedStatus = null;
                    });
                    _loadOrders();
                  },
                ),
                SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Menunggu Bayar',
                  selected: _selectedStatus == 'pending_payment',
                  color: Colors.amber,
                  onTap: () {
                    setState(() {
                      _selectedStatus = 'pending_payment';
                    });
                    _loadOrders();
                  },
                ),
                SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Diproses',
                  selected: _selectedStatus == 'processing',
                  color: Colors.blue,
                  onTap: () {
                    setState(() {
                      _selectedStatus = 'processing';
                    });
                    _loadOrders();
                  },
                ),
                SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Dikirim',
                  selected: _selectedStatus == 'shipped',
                  color: Colors.indigo,
                  onTap: () {
                    setState(() {
                      _selectedStatus = 'shipped';
                    });
                    _loadOrders();
                  },
                ),
                SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Selesai',
                  selected: _selectedStatus == 'completed',
                  color: Colors.green,
                  onTap: () {
                    setState(() {
                      _selectedStatus = 'completed';
                    });
                    _loadOrders();
                  },
                ),
                SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Dibatalkan',
                  selected: _selectedStatus == 'cancelled',
                  color: Colors.red,
                  onTap: () {
                    setState(() {
                      _selectedStatus = 'cancelled';
                    });
                    _loadOrders();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    int pendingCount = 0;
    int processingCount = 0;
    int shippedCount = 0;

    if (_stats['pending_payment'] != null) {
      pendingCount = (_stats['pending_payment']['count'] ?? 0) as int;
    }
    if (_stats['processing'] != null) {
      processingCount = (_stats['processing']['count'] ?? 0) as int;
    }
    if (_stats['shipped'] != null) {
      shippedCount = (_stats['shipped']['count'] ?? 0) as int;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Menunggu', pendingCount, Colors.amber),
          Container(width: 1, height: 30, color: Colors.grey[300]),
          _buildStatItem('Diproses', processingCount, Colors.blue),
          Container(width: 1, height: 30, color: Colors.grey[300]),
          _buildStatItem('Dikirim', shippedCount, Colors.indigo),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? (color ?? Colors.deepOrange).withOpacity(0.2)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? (color ?? Colors.deepOrange) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? (color ?? Colors.deepOrange) : Colors.grey[700],
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.deepOrange),
            SizedBox(height: 16),
            Text('Memuat data pesanan...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Gagal memuat data',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _loadOrders(),
                icon: Icon(Icons.refresh),
                label: Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Tidak ada pesanan ditemukan',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadOrders(),
      child: ListView.builder(
        padding: EdgeInsets.all(12),
        itemCount: _orders.length + (_pagination['has_more'] == true ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _orders.length) {
            return _buildLoadMoreButton();
          }
          return _buildOrderCard(_orders[index]);
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending_payment';
    final paymentStatus = order['payment_status'] ?? 'pending';

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.done_all;
        break;
      case 'shipped':
        statusColor = Colors.indigo;
        statusIcon = Icons.local_shipping;
        break;
      case 'delivered':
        statusColor = Colors.teal;
        statusIcon = Icons.check_circle;
        break;
      case 'processing':
        statusColor = Colors.blue;
        statusIcon = Icons.hourglass_top;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'refunded':
        statusColor = Colors.purple;
        statusIcon = Icons.replay;
        break;
      default:
        statusColor = Colors.amber;
        statusIcon = Icons.pending;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showOrderDetail(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 24),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${order['order_number'] ?? order['id']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          order['buyer_name'] ?? order['buyer_email'] ?? '-',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _currencyFormat.format(order['total_price'] ?? 0),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _formatStatus(status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12),
              Divider(height: 1),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                  SizedBox(width: 4),
                  Text(
                    _formatDate(order['created_at']),
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.inventory_2, size: 14, color: Colors.grey[500]),
                  SizedBox(width: 4),
                  Text(
                    '${order['total_items'] ?? order['item_count'] ?? 0} item',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  Spacer(),
                  // Payment status
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getPaymentStatusColor(
                        paymentStatus,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatPaymentStatus(paymentStatus),
                      style: TextStyle(
                        color: _getPaymentStatusColor(paymentStatus),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (order['tracking_number'] != null) ...[
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.local_shipping, size: 14, color: Colors.indigo),
                    SizedBox(width: 4),
                    Text(
                      'Resi: ${order['tracking_number']}',
                      style: TextStyle(
                        color: Colors.indigo,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 12),
              // Action buttons
              Row(
                children: [
                  if (status != 'cancelled' &&
                      status != 'completed' &&
                      status != 'refunded') ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showStatusDialog(order['id'], status),
                        icon: Icon(Icons.edit, size: 16),
                        label: Text('Status'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.deepOrange,
                          side: BorderSide(color: Colors.deepOrange),
                          padding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                  ],
                  if (status == 'processing') ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showTrackingDialog(order['id']),
                        icon: Icon(Icons.local_shipping, size: 16),
                        label: Text('Input Resi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                  ],
                  if (status != 'cancelled' &&
                      status != 'completed' &&
                      status != 'refunded')
                    IconButton(
                      onPressed: () => _cancelOrder(
                        order['id'],
                        order['order_number'] ?? '${order['id']}',
                      ),
                      icon: Icon(Icons.cancel, color: Colors.red),
                      tooltip: 'Batalkan',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: ElevatedButton(
          onPressed: () {
            final currentOffset = _pagination['offset'] ?? 0;
            final limit = _pagination['limit'] ?? 20;
            _loadOrders(offset: currentOffset + limit);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
          ),
          child: Text('Muat Lebih Banyak'),
        ),
      ),
    );
  }

  void _showOrderDetail(Map<String, dynamic> order) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          Center(child: CircularProgressIndicator(color: Colors.deepOrange)),
    );

    try {
      final detail = await ApiService.getAdminOrderDetail(order['id']);
      Navigator.pop(context); // Close loading

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Detail Pesanan #${detail['order_number'] ?? detail['id']}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                _buildDetailRow('Status', _formatStatus(detail['status'])),
                _buildDetailRow(
                  'Pembayaran',
                  _formatPaymentStatus(detail['payment_status']),
                ),
                _buildDetailRow(
                  'Metode Bayar',
                  detail['payment_method'] ?? '-',
                ),
                if (detail['tracking_number'] != null)
                  _buildDetailRow('No. Resi', detail['tracking_number']),
                Divider(height: 24),
                Text('Pembeli', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                _buildDetailRow('Nama', detail['buyer_name'] ?? '-'),
                _buildDetailRow('Email', detail['buyer_email'] ?? '-'),
                _buildDetailRow(
                  'Telepon',
                  detail['buyer_phone'] ?? detail['shipping_phone'] ?? '-',
                ),
                _buildDetailRow(
                  'Penerima',
                  detail['shipping_recipient'] ?? '-',
                ),
                _buildDetailRow('Alamat', detail['shipping_address'] ?? '-'),
                Divider(height: 24),
                Text(
                  'Item Pesanan',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                if (detail['items'] != null)
                  ...List<Map<String, dynamic>>.from(detail['items']).map(
                    (item) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              width: 40,
                              height: 40,
                              color: Colors.grey[200],
                              child: item['product_image'] != null
                                  ? Image.network(
                                      item['product_image'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.image,
                                        size: 20,
                                        color: Colors.grey,
                                      ),
                                    )
                                  : Icon(
                                      Icons.inventory_2,
                                      size: 20,
                                      color: Colors.grey,
                                    ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['product_name'] ?? '-',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${item['quantity']}x @ ${_currencyFormat.format(item['price'] ?? 0)}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _currencyFormat.format(item['subtotal'] ?? 0),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal'),
                    Text(
                      _currencyFormat.format(
                        (detail['total_price'] ?? 0) -
                            (detail['shipping_cost'] ?? 0) +
                            (detail['discount_amount'] ?? 0),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ongkir'),
                    Text(_currencyFormat.format(detail['shipping_cost'] ?? 0)),
                  ],
                ),
                if ((detail['discount_amount'] ?? 0) > 0) ...[
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Diskon'),
                      Text(
                        '-${_currencyFormat.format(detail['discount_amount'] ?? 0)}',
                        style: TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                ],
                Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _currencyFormat.format(detail['total_price'] ?? 0),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Divider(),
                _buildDetailRow('Dibuat', _formatDate(detail['created_at'])),
                if (detail['paid_at'] != null)
                  _buildDetailRow('Dibayar', _formatDate(detail['paid_at'])),
                if (detail['shipped_at'] != null)
                  _buildDetailRow('Dikirim', _formatDate(detail['shipped_at'])),
                if (detail['admin_notes'] != null &&
                    detail['admin_notes'].toString().isNotEmpty)
                  _buildDetailRow('Catatan Admin', detail['admin_notes']),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat detail: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  String _formatStatus(String? status) {
    switch (status) {
      case 'pending_payment':
        return 'Menunggu Bayar';
      case 'processing':
        return 'Diproses';
      case 'shipped':
        return 'Dikirim';
      case 'delivered':
        return 'Terkirim';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      case 'refunded':
        return 'Refund';
      default:
        return status ?? '-';
    }
  }

  String _formatPaymentStatus(String? status) {
    switch (status) {
      case 'pending':
        return 'Belum Bayar';
      case 'paid':
      case 'settlement':
        return 'Lunas';
      case 'failed':
        return 'Gagal';
      case 'refunded':
        return 'Refund';
      default:
        return status ?? '-';
    }
  }

  Color _getPaymentStatusColor(String? status) {
    switch (status) {
      case 'paid':
      case 'settlement':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.purple;
      default:
        return Colors.amber;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return _dateFormat.format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
