import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rempah_nusantara/config/app_theme.dart';
import 'package:rempah_nusantara/services/api_service.dart';
import 'package:rempah_nusantara/utils/image_utils.dart';
import 'package:intl/intl.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Map<String, dynamic>>> _productsFuture;
  Map<String, dynamic>? _dashboardData;
  bool _isLoadingDashboard = true;
  String _dashboardError = '';
  bool _isSellerCheckDone = false;
  bool _isSeller = false;

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkSellerStatus();
  }

  Future<void> _checkSellerStatus() async {
    // First check from stored role
    if (ApiService.isSeller) {
      setState(() {
        _isSeller = true;
        _isSellerCheckDone = true;
      });
      _productsFuture = _fetchProducts();
      _fetchDashboard();
      return;
    }

    // If not stored, fetch from API
    if (ApiService.isAuthenticated && ApiService.currentUserId != null) {
      try {
        final profile = await ApiService.getProfile(ApiService.currentUserId!);
        final role = profile['role'] ?? 'buyer';
        final isSeller = role == 'seller' || role == 'admin';

        // Update stored role
        if (profile['role'] != null) {
          await ApiService.setUserRole(profile['role']);
        }

        if (mounted) {
          setState(() {
            _isSeller = isSeller;
            _isSellerCheckDone = true;
          });

          if (isSeller) {
            _productsFuture = _fetchProducts();
            _fetchDashboard();
          }
        }
      } catch (e) {
        print('Error checking seller status: $e');
        if (mounted) {
          setState(() {
            _isSeller = false;
            _isSellerCheckDone = true;
          });
        }
      }
    } else {
      setState(() {
        _isSellerCheckDone = true;
        _isSeller = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboard() async {
    if (!ApiService.isAuthenticated || ApiService.currentUserId == null) {
      setState(() {
        _isLoadingDashboard = false;
        _dashboardError = 'Anda harus login terlebih dahulu';
      });
      return;
    }

    try {
      final data = await ApiService.getSellerDashboard(days: 30);
      if (mounted) {
        setState(() {
          _dashboardData = data;
          _isLoadingDashboard = false;
        });
      }
    } catch (e) {
      print('Error fetching dashboard: $e');
      if (mounted) {
        setState(() {
          _isLoadingDashboard = false;
          _dashboardError = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchProducts() async {
    if (!ApiService.isAuthenticated || ApiService.currentUserId == null) {
      return [];
    }

    try {
      return await ApiService.getProducts(
        sellerId: ApiService.currentUserId,
        limit: 100,
        orderBy: 'created_at',
        orderDir: 'DESC',
      );
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  void _refreshAll() {
    setState(() {
      _productsFuture = _fetchProducts();
      _isLoadingDashboard = true;
      _dashboardError = '';
    });
    _fetchDashboard();
  }

  Future<void> _deleteProduct(int productId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            const Text('Hapus Produk'),
          ],
        ),
        content: const Text('Apakah Anda yakin ingin menghapus produk ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Batal',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.deleteProduct(productId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Produk berhasil dihapus'),
              backgroundColor: AppColors.success,
            ),
          );
          _refreshAll();
        }
      } catch (e) {
        print('Error deleting product: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus produk: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking seller status
    if (!_isSellerCheckDone) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'Dashboard Penjual',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // Show seller signup prompt if not a seller
    if (!_isSeller) {
      return _buildNotSellerView();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Dashboard Penjual',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _refreshAll,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Overview'),
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Produk'),
            Tab(icon: Icon(Icons.shopping_bag_outlined), text: 'Pesanan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildOverviewTab(), _buildProductsTab(), _buildOrdersTab()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await context.push('/edit-product');
          if (result == true) {
            _refreshAll();
          }
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Tambah Produk',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ==================== NOT SELLER VIEW ====================

  Widget _buildNotSellerView() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Mulai Berjualan',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.secondary.withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.storefront_outlined,
                  size: 80,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Jadi Penjual di\nRempah Nusantara',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Mulai jual produk rempah berkualitas Anda\ndan jangkau pelanggan di seluruh Indonesia',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              // Benefits
              _buildBenefitItem(
                Icons.trending_up,
                'Tingkatkan Penjualan',
                'Akses ke ribuan pelanggan potensial',
              ),
              _buildBenefitItem(
                Icons.dashboard_outlined,
                'Dashboard Lengkap',
                'Kelola produk dan pesanan dengan mudah',
              ),
              _buildBenefitItem(
                Icons.payments_outlined,
                'Pembayaran Aman',
                'Sistem pembayaran terintegrasi dan aman',
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await context.push('/seller-signup');
                    if (result == true || mounted) {
                      // Recheck seller status after returning
                      _checkSellerStatus();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Daftar Jadi Penjual',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.pop(),
                child: Text(
                  'Nanti Saja',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== OVERVIEW TAB ====================

  Widget _buildOverviewTab() {
    if (_isLoadingDashboard) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_dashboardError.isNotEmpty) {
      return _buildErrorState(_dashboardError);
    }

    if (_dashboardData == null) {
      return _buildEmptyState('Data dashboard tidak tersedia');
    }

    final products = _dashboardData!['products'] ?? {};
    final orders = _dashboardData!['orders'] ?? {};
    final sales = _dashboardData!['sales'] ?? {};
    final rating = _dashboardData!['rating'] ?? {};
    final topProducts = _dashboardData!['top_products'] ?? [];
    final recentOrders = _dashboardData!['recent_orders'] ?? [];

    return RefreshIndicator(
      onRefresh: () async => _fetchDashboard(),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '📅 Data 30 hari terakhir',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stats Grid
            _buildStatsGrid(products, orders, sales, rating),
            const SizedBox(height: 24),

            // Orders by Status
            if ((orders['by_status'] as Map?)?.isNotEmpty ?? false) ...[
              _buildSectionTitle('Status Pesanan'),
              const SizedBox(height: 12),
              _buildOrderStatusCards(orders['by_status'] as Map),
              const SizedBox(height: 24),
            ],

            // Top Products
            if ((topProducts as List).isNotEmpty) ...[
              _buildSectionTitle('Produk Terlaris'),
              const SizedBox(height: 12),
              _buildTopProductsList(topProducts),
              const SizedBox(height: 24),
            ],

            // Recent Orders
            if ((recentOrders as List).isNotEmpty) ...[
              _buildSectionTitle('Pesanan Terbaru'),
              const SizedBox(height: 12),
              _buildRecentOrdersList(recentOrders),
            ],

            const SizedBox(height: 80), // FAB space
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(Map products, Map orders, Map sales, Map rating) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          'Total Produk',
          '${products['total'] ?? 0}',
          Icons.inventory_2_outlined,
          AppColors.primary,
        ),
        _buildStatCard(
          'Total Stok',
          '${products['total_stock'] ?? 0}',
          Icons.all_inbox_outlined,
          AppColors.secondary,
        ),
        _buildStatCard(
          'Total Pesanan',
          '${orders['total'] ?? 0}',
          Icons.shopping_bag_outlined,
          Colors.blue,
        ),
        _buildStatCard(
          'Pendapatan',
          _currencyFormat.format(sales['total_revenue'] ?? 0),
          Icons.account_balance_wallet_outlined,
          Colors.green,
          isSmallText: true,
        ),
        _buildStatCard(
          'Terjual',
          '${sales['total_items_sold'] ?? 0} item',
          Icons.trending_up_outlined,
          Colors.orange,
        ),
        _buildStatCard(
          'Rating',
          '${(rating['average'] ?? 0).toStringAsFixed(1)} ⭐',
          Icons.star_outline,
          Colors.amber,
          subtitle: '${rating['total_reviews'] ?? 0} ulasan',
        ),
        if ((products['low_stock_count'] ?? 0) > 0)
          _buildStatCard(
            'Stok Menipis',
            '${products['low_stock_count']}',
            Icons.warning_amber_outlined,
            AppColors.error,
          ),
        if ((orders['pending_action'] ?? 0) > 0)
          _buildStatCard(
            'Perlu Tindakan',
            '${orders['pending_action']}',
            Icons.pending_actions_outlined,
            AppColors.error,
          ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
    bool isSmallText = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallText ? 16 : 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusCards(Map statusData) {
    final statusColors = {
      'pending': Colors.orange,
      'pending_payment': Colors.amber,
      'processing': Colors.blue,
      'shipped': Colors.indigo,
      'delivered': Colors.green,
      'completed': AppColors.success,
      'cancelled': AppColors.error,
    };

    final statusLabels = {
      'pending': 'Menunggu',
      'pending_payment': 'Menunggu Bayar',
      'processing': 'Diproses',
      'shipped': 'Dikirim',
      'delivered': 'Terkirim',
      'completed': 'Selesai',
      'cancelled': 'Dibatalkan',
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: statusData.entries.map((entry) {
        final status = entry.key;
        final count = entry.value;
        final color = statusColors[status] ?? Colors.grey;
        final label = statusLabels[status] ?? status;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                '$label ($count)',
                style: AppTextStyles.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopProductsList(List products) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length > 5 ? 5 : products.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final product = products[index];
          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ImageUtils.buildImage(
                imageUrl: product['image_url'],
                productName: product['name'] ?? 'Produk',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              product['name'] ?? 'Produk',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              _currencyFormat.format(product['price'] ?? 0),
              style: AppTextStyles.caption.copyWith(color: AppColors.primary),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${product['total_sold'] ?? 0} terjual',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  _currencyFormat.format(product['total_revenue'] ?? 0),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.success,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            onTap: () => context.push('/product/${product['id']}'),
          );
        },
      ),
    );
  }

  Widget _buildRecentOrdersList(List orders) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: orders.length > 5 ? 5 : orders.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final order = orders[index];
          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            title: Text(
              order['order_number'] ?? '#${order['id']}',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              order['buyer_name'] ?? 'Pembeli',
              style: AppTextStyles.caption,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _currencyFormat.format(order['total_price'] ?? 0),
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                _buildStatusBadge(order['status'] ?? 'pending'),
              ],
            ),
            onTap: () => context.push('/order-status/${order['id']}'),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final statusColors = {
      'pending': Colors.orange,
      'pending_payment': Colors.amber,
      'processing': Colors.blue,
      'shipped': Colors.indigo,
      'delivered': Colors.green,
      'completed': AppColors.success,
      'cancelled': AppColors.error,
    };

    final color = statusColors[status] ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // ==================== PRODUCTS TAB ====================

  Widget _buildProductsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final products = snapshot.data ?? [];

        if (products.isEmpty) {
          return _buildEmptyProductsState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _productsFuture = _fetchProducts();
            });
          },
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildProductsHeader(products),
                _buildProductList(products),
                const SizedBox(height: 80), // FAB space
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductsHeader(List<Map<String, dynamic>> products) {
    int totalStock = products.fold(
      0,
      (sum, item) => sum + (item['stock'] as int? ?? 0),
    );
    int lowStock = products.where((p) => (p['stock'] as int? ?? 0) < 10).length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildMiniStatCard(
              'Total Produk',
              products.length.toString(),
              Icons.inventory_2_outlined,
              AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMiniStatCard(
              'Total Stok',
              totalStock.toString(),
              Icons.all_inbox_outlined,
              AppColors.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMiniStatCard(
              'Stok Menipis',
              lowStock.toString(),
              Icons.warning_amber_outlined,
              lowStock > 0 ? AppColors.error : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(List<Map<String, dynamic>> products) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final imageUrl = product['image_url'] as String?;
    final stock = product['stock'] as int? ?? 0;
    final isLowStock = stock < 10;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isLowStock
              ? AppColors.error.withOpacity(0.3)
              : AppColors.border.withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ImageUtils.buildImage(
                imageUrl: imageUrl,
                productName: product['name'] ?? 'Produk',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'Produk',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currencyFormat.format(product['price'] ?? 0),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isLowStock
                              ? AppColors.error.withOpacity(0.1)
                              : AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Stok: $stock',
                          style: AppTextStyles.caption.copyWith(
                            color: isLowStock
                                ? AppColors.error
                                : AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isLowStock) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: AppColors.error,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: Colors.blue,
                      size: 18,
                    ),
                  ),
                  onPressed: () async {
                    final result = await context.push(
                      '/edit-product',
                      extra: product['id'],
                    );
                    if (result == true) {
                      _refreshAll();
                    }
                  },
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                      size: 18,
                    ),
                  ),
                  onPressed: () => _deleteProduct(product['id']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ORDERS TAB ====================

  Widget _buildOrdersTab() {
    if (_isLoadingDashboard) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final recentOrders = _dashboardData?['recent_orders'] as List? ?? [];

    if (recentOrders.isEmpty) {
      return _buildEmptyState('Belum ada pesanan');
    }

    return RefreshIndicator(
      onRefresh: () async => _fetchDashboard(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: recentOrders.length,
        itemBuilder: (context, index) {
          final order = recentOrders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: () => context.push('/order-status/${order['id']}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order['order_number'] ?? '#${order['id']}',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusBadge(order['status'] ?? 'pending'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    order['buyer_name'] ?? 'Pembeli',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    _currencyFormat.format(order['total_price'] ?? 0),
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== HELPER WIDGETS ====================

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.heading3.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyProductsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.storefront_outlined,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Belum Ada Produk',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mulai jual produk rempah Anda\ndengan menekan tombol di bawah',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await context.push('/edit-product');
              if (result == true) {
                _refreshAll();
              }
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Tambah Produk Pertama',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Terjadi Kesalahan',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshAll,
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text(
              'Coba Lagi',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
