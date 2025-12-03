import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/config/app_theme.dart';
import 'package:myapp/widgets/bottom_nav_bar.dart';
import 'package:myapp/services/api_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  final List<String> _tabs = [
    'Semua',
    'Dikemas',
    'Dikirim',
    'Selesai',
    'Dibatalkan',
  ];

  List<Map<String, dynamic>> _orders = [];

  // Mock order data (fallback)
  final List<Map<String, dynamic>> _mockOrders = [
    {
      'id': 'ORD-2024-001',
      'date': '15 Jan 2024',
      'status': 'Dikirim',
      'total': 125000,
      'items': [
        {
          'name': 'Kayu Manis Premium',
          'quantity': 2,
          'price': 45000,
          'image': 'assets/images/cinnamon.jpg',
        },
        {
          'name': 'Pala Utuh',
          'quantity': 1,
          'price': 35000,
          'image': 'assets/images/nutmeg.jpg',
        },
      ],
      'trackingNumber': 'JNE1234567890',
      'estimatedDelivery': '18 Jan 2024',
    },
    {
      'id': 'ORD-2024-002',
      'date': '12 Jan 2024',
      'status': 'Selesai',
      'total': 89000,
      'items': [
        {
          'name': 'Cengkeh Premium',
          'quantity': 1,
          'price': 55000,
          'image': 'assets/images/cloves.jpg',
        },
        {
          'name': 'Jintan Hitam',
          'quantity': 1,
          'price': 34000,
          'image': 'assets/images/cumin.jpg',
        },
      ],
      'trackingNumber': 'JNE0987654321',
      'deliveredDate': '14 Jan 2024',
    },
    {
      'id': 'ORD-2024-003',
      'date': '10 Jan 2024',
      'status': 'Dikemas',
      'total': 156000,
      'items': [
        {
          'name': 'Lada Hitam Premium',
          'quantity': 3,
          'price': 52000,
          'image': 'assets/images/pepper.jpg',
        },
      ],
      'estimatedDelivery': '17 Jan 2024',
    },
    {
      'id': 'ORD-2023-125',
      'date': '28 Des 2023',
      'status': 'Dibatalkan',
      'total': 75000,
      'items': [
        {
          'name': 'Kunyit Bubuk',
          'quantity': 2,
          'price': 37500,
          'image': 'assets/images/turmeric.jpg',
        },
      ],
      'cancelReason': 'Dibatalkan oleh pembeli',
      'cancelDate': '29 Des 2023',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);

    try {
      print('📦 [ORDERS] Loading orders from API...');
      final orders = await ApiService.getOrders();
      print('✅ [ORDERS] Received ${orders.length} orders');
      print('📊 [ORDERS] Orders data: $orders');

      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
        print('🔄 [ORDERS] State updated with ${_orders.length} orders');
      }
    } catch (e) {
      print('❌ [ORDERS] Error loading orders: $e');
      if (mounted) {
        setState(() {
          _orders = _mockOrders; // Fallback to mock data
          _isLoading = false;
        });
        print('⚠️ [ORDERS] Using mock data (${_mockOrders.length} orders)');
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredOrders() {
    final currentTab = _tabs[_tabController.index];
    final ordersToFilter = _orders.isEmpty ? _mockOrders : _orders;

    print('🔍 [ORDERS] Filtering for tab: $currentTab');
    print('📊 [ORDERS] Total orders to filter: ${ordersToFilter.length}');

    if (currentTab == 'Semua') {
      print('✅ [ORDERS] Showing all ${ordersToFilter.length} orders');
      return ordersToFilter;
    }

    return ordersToFilter.where((order) {
      final orderStatus = order['status']?.toString().toLowerCase() ?? '';
      final paymentStatus =
          order['payment_status']?.toString().toLowerCase() ?? '';

      if (currentTab == 'Dikemas') {
        return orderStatus == 'processing' ||
            orderStatus == 'pending_payment' && paymentStatus == 'paid';
      } else if (currentTab == 'Dikirim') {
        return orderStatus == 'shipped';
      } else if (currentTab == 'Selesai') {
        return orderStatus == 'completed';
      } else if (currentTab == 'Dibatalkan') {
        return orderStatus == 'cancelled';
      }
      return false;
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Dikemas':
        return Colors.orange;
      case 'Dikirim':
        return Colors.blue;
      case 'Selesai':
        return AppColors.primary;
      case 'Dibatalkan':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Dikemas':
        return Icons.inventory_2_outlined;
      case 'Dikirim':
        return Icons.local_shipping_outlined;
      case 'Selesai':
        return Icons.check_circle_outline;
      case 'Dibatalkan':
        return Icons.cancel_outlined;
      default:
        return Icons.shopping_bag_outlined;
    }
  }

  Future<void> _refreshOrders() async {
    await _loadOrders();
  }

  void _viewOrderDetail(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildOrderDetailSheet(order),
    );
  }

  void _trackOrder(Map<String, dynamic> order) {
    // Navigate to tracking screen (to be implemented)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tracking: ${order['trackingNumber']}'),
        action: SnackBarAction(label: 'Salin', onPressed: () {}),
      ),
    );
  }

  void _reorder(Map<String, dynamic> order) {
    // Add items to cart (to be implemented)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Produk ditambahkan ke keranjang')),
    );
  }

  void _rateOrder(Map<String, dynamic> order) {
    // Navigate to rating screen (to be implemented)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Beri Penilaian'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bagaimana pengalaman belanja Anda?'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => IconButton(
                  icon: Icon(
                    Icons.star_outline,
                    color: AppColors.primary,
                    size: 32,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Terima kasih atas penilaian Anda!'),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailSheet(Map<String, dynamic> order) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order['id'], style: AppTextStyles.heading2),
                            const SizedBox(height: 4),
                            Text(
                              order['date'],
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              order['status'],
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(order['status']),
                                size: 16,
                                color: _getStatusColor(order['status']),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                order['status'],
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: _getStatusColor(order['status']),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Tracking info
                    if (order['trackingNumber'] != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[100]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.local_shipping,
                                  color: Colors.blue[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Nomor Resi',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  order['trackingNumber'],
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _trackOrder(order),
                                  child: const Text('Lacak'),
                                ),
                              ],
                            ),
                            if (order['estimatedDelivery'] != null) ...[
                              const Divider(height: 16),
                              Row(
                                children: [
                                  Icon(
                                    Icons.event,
                                    color: Colors.grey[600],
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Estimasi tiba: ${order['estimatedDelivery']}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Order items
                    Text('Produk Pesanan', style: AppTextStyles.heading3),
                    const SizedBox(height: 12),
                    ...List.generate(order['items'].length, (index) {
                      final item = order['items'][index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[200]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            // Product image placeholder
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.image, color: Colors.grey[400]),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'],
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item['quantity']}x',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Total: Rp ${_formatCurrency(order['total'])}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 24),

                    // Total
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Pembayaran',
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Rp ${order['total'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                            style: AppTextStyles.heading2.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    if (order['status'] == 'Selesai') ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.pop();
                            _rateOrder(order);
                          },
                          icon: const Icon(Icons.star_outline),
                          label: const Text('Beri Penilaian'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.pop();
                            _reorder(order);
                          },
                          icon: const Icon(Icons.shopping_cart_outlined),
                          label: const Text('Pesan Lagi'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ] else if (order['status'] == 'Dikirim') ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.pop();
                            _trackOrder(order);
                          },
                          icon: const Icon(Icons.my_location),
                          label: const Text('Lacak Pesanan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatCurrency(dynamic amount) {
    final value = (amount is String)
        ? double.tryParse(amount) ?? 0
        : (amount ?? 0);
    final numValue = value is num ? value : 0;
    return numValue
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is num) return price.toDouble();
    if (price is String) return double.tryParse(price) ?? 0.0;
    return 0.0;
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending_payment':
        return 'Menunggu Pembayaran';
      case 'processing':
        return 'Dikemas';
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

  Widget _buildOrderCard(Map<String, dynamic> order) {
    // Normalize order data
    final orderNumber = order['order_number'] ?? 'ORD-${order['id']}';
    final orderDate = _formatDate(order['created_at'] ?? '');
    final orderStatus = _formatStatus(order['status'] ?? 'pending_payment');
    final totalPrice = _parsePrice(order['total_price']);
    final shippingCost = _parsePrice(order['shipping_cost']);
    final items = (order['items'] ?? []) as List;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () => _viewOrderDetail(order),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            orderNumber,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            orderDate,
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(orderStatus).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(orderStatus),
                          size: 14,
                          color: _getStatusColor(orderStatus),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          orderStatus,
                          style: AppTextStyles.caption.copyWith(
                            color: _getStatusColor(orderStatus),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Order items preview
              ...List.generate(items.length > 2 ? 2 : items.length, (index) {
                final item = items[index];
                final itemName =
                    item['product_name'] ?? item['name'] ?? 'Produk';
                final itemQty = item['quantity'] ?? 1;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.image,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          itemName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                      Text(
                        '${itemQty}x',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (items.length > 2)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '+${items.length - 2} produk lainnya',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Divider
              Divider(color: Colors.grey[200], height: 1),
              const SizedBox(height: 16),

              // Total and action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Pembayaran',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          if (shippingCost > 0)
                            Text(
                              'Ongkir: Rp ${_formatCurrency(shippingCost)}',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                      Text(
                        'Rp ${_formatCurrency(totalPrice)}',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  if (order['status'] == 'Dikirim')
                    OutlinedButton(
                      onPressed: () => _trackOrder(order),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Lacak'),
                    )
                  else if (order['status'] == 'Selesai')
                    OutlinedButton(
                      onPressed: () => _reorder(order),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Pesan Lagi'),
                    )
                  else
                    OutlinedButton(
                      onPressed: () => _viewOrderDetail(order),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Detail'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/'),
        ),
        title: Text('Pesanan Saya', style: AppTextStyles.heading2),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: AppTextStyles.bodyMedium,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(width: 3, color: AppColors.primary),
                insets: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onTap: (_) => setState(() {}),
              tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshOrders,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: _tabs.map((tab) {
                  final filteredOrders = _getFilteredOrders();

                  if (filteredOrders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada pesanan',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pesanan Anda akan muncul di sini',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => context.go('/'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Belanja Sekarang'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: filteredOrders
                        .map((order) => _buildOrderCard(order))
                        .toList(),
                  );
                }).toList(),
              ),
      ),
      bottomNavigationBar: const BottomNavBar(currentRoute: '/orders'),
    );
  }
}
