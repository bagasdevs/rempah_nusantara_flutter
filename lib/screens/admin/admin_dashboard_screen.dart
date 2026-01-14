import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _dashboardData;
  int _selectedDays = 30;

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await ApiService.getAdminDashboard(days: _selectedDays);
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Filter Periode',
            onSelected: (days) {
              setState(() {
                _selectedDays = days;
              });
              _loadDashboard();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 7, child: Text('7 Hari Terakhir')),
              PopupMenuItem(value: 30, child: Text('30 Hari Terakhir')),
              PopupMenuItem(value: 90, child: Text('90 Hari Terakhir')),
              PopupMenuItem(value: 365, child: Text('1 Tahun Terakhir')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboard,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _buildBody(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.deepOrange),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 35,
                    color: Colors.deepOrange,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ReNusa',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard, color: Colors.deepOrange),
            title: Text('Dashboard'),
            selected: true,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.people),
            title: Text('Kelola Pengguna'),
            onTap: () {
              Navigator.pop(context);
              context.push('/admin/users');
            },
          ),
          ListTile(
            leading: Icon(Icons.inventory_2),
            title: Text('Kelola Produk'),
            onTap: () {
              Navigator.pop(context);
              context.push('/admin/products');
            },
          ),
          ListTile(
            leading: Icon(Icons.shopping_bag),
            title: Text('Kelola Pesanan'),
            onTap: () {
              Navigator.pop(context);
              context.push('/admin/orders');
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Kembali ke Beranda'),
            onTap: () {
              Navigator.pop(context);
              context.go('/');
            },
          ),
        ],
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
            Text('Memuat data dashboard...'),
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
                'Gagal memuat dashboard',
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
                onPressed: _loadDashboard,
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

    if (_dashboardData == null) {
      return Center(child: Text('Tidak ada data'));
    }

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period indicator
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.deepOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Data $_selectedDays hari terakhir',
                style: TextStyle(
                  color: Colors.deepOrange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 16),

            // Quick Stats Grid
            _buildQuickStatsGrid(),
            SizedBox(height: 24),

            // Navigation Cards
            _buildNavigationCards(),
            SizedBox(height: 24),

            // Revenue Section
            _buildRevenueSection(),
            SizedBox(height: 24),

            // Top Sellers
            _buildTopSellersSection(),
            SizedBox(height: 24),

            // Top Products
            _buildTopProductsSection(),
            SizedBox(height: 24),

            // Recent Orders
            _buildRecentOrdersSection(),
            SizedBox(height: 24),

            // Recent Users
            _buildRecentUsersSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsGrid() {
    final users = _dashboardData!['users'] ?? {};
    final products = _dashboardData!['products'] ?? {};
    final orders = _dashboardData!['orders'] ?? {};
    final revenue = _dashboardData!['revenue'] ?? {};

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Pengguna',
          '${users['total'] ?? 0}',
          Icons.people,
          Colors.blue,
          subtitle: '+${users['new_in_period'] ?? 0} baru',
        ),
        _buildStatCard(
          'Total Produk',
          '${products['total'] ?? 0}',
          Icons.inventory_2,
          Colors.green,
          subtitle: '${products['out_of_stock'] ?? 0} habis',
        ),
        _buildStatCard(
          'Pesanan',
          '${orders['total_in_period'] ?? 0}',
          Icons.shopping_bag,
          Colors.orange,
          subtitle: '${orders['pending_action'] ?? 0} pending',
        ),
        _buildStatCard(
          'Pendapatan',
          _currencyFormat.format(revenue['total_in_period'] ?? 0),
          Icons.attach_money,
          Colors.purple,
          subtitle: 'Periode ini',
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
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavigationCards() {
    return Row(
      children: [
        Expanded(
          child: _buildNavCard(
            'Pengguna',
            Icons.people,
            Colors.blue,
            () => context.push('/admin/users'),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildNavCard(
            'Produk',
            Icons.inventory_2,
            Colors.green,
            () => context.push('/admin/products'),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildNavCard(
            'Pesanan',
            Icons.shopping_bag,
            Colors.orange,
            () => context.push('/admin/orders'),
          ),
        ),
      ],
    );
  }

  Widget _buildNavCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueSection() {
    final revenue = _dashboardData!['revenue'] ?? {};
    final allTimeRevenue = (revenue['all_time'] ?? 0).toDouble();
    final avgOrderValue = (revenue['avg_order_value'] ?? 0).toDouble();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Pendapatan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Semua Waktu',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _currencyFormat.format(allTimeRevenue),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey[300]),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rata-rata Pesanan',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _currencyFormat.format(avgOrderValue),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopSellersSection() {
    final topSellers = List<Map<String, dynamic>>.from(
      _dashboardData!['top_sellers'] ?? [],
    );

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Penjual',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => context.push('/admin/users?role=seller'),
                child: Text('Lihat Semua'),
              ),
            ],
          ),
          SizedBox(height: 8),
          if (topSellers.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Belum ada data penjual',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...topSellers.take(5).map((seller) => _buildSellerTile(seller)),
        ],
      ),
    );
  }

  Widget _buildSellerTile(Map<String, dynamic> seller) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.orange.withOpacity(0.2),
        child: Text(
          (seller['full_name'] ?? seller['email'] ?? 'S')
              .toString()
              .substring(0, 1)
              .toUpperCase(),
          style: TextStyle(
            color: Colors.orange[700],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        seller['business_name'] ??
            seller['full_name'] ??
            seller['email'] ??
            '-',
        style: TextStyle(fontWeight: FontWeight.w500),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${seller['product_count'] ?? 0} produk • ${seller['total_sold'] ?? 0} terjual',
        style: TextStyle(fontSize: 12),
      ),
      trailing: Text(
        _currencyFormat.format(seller['total_revenue'] ?? 0),
        style: TextStyle(
          color: Colors.green[700],
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTopProductsSection() {
    final topProducts = List<Map<String, dynamic>>.from(
      _dashboardData!['top_products'] ?? [],
    );

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Produk Terlaris',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => context.push('/admin/products'),
                child: Text('Lihat Semua'),
              ),
            ],
          ),
          SizedBox(height: 8),
          if (topProducts.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Belum ada data produk',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...topProducts.take(5).map((product) => _buildProductTile(product)),
        ],
      ),
    );
  }

  Widget _buildProductTile(Map<String, dynamic> product) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 48,
          height: 48,
          color: Colors.grey[200],
          child: product['image_url'] != null
              ? Image.network(
                  product['image_url'],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.image, color: Colors.grey),
                )
              : Icon(Icons.inventory_2, color: Colors.grey),
        ),
      ),
      title: Text(
        product['name'] ?? '-',
        style: TextStyle(fontWeight: FontWeight.w500),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${product['total_sold'] ?? 0} terjual • Stok: ${product['stock'] ?? 0}',
        style: TextStyle(fontSize: 12),
      ),
      trailing: Text(
        _currencyFormat.format(product['total_revenue'] ?? 0),
        style: TextStyle(
          color: Colors.green[700],
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildRecentOrdersSection() {
    final recentOrders = List<Map<String, dynamic>>.from(
      _dashboardData!['recent_orders'] ?? [],
    );

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pesanan Terbaru',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => context.push('/admin/orders'),
                child: Text('Lihat Semua'),
              ),
            ],
          ),
          SizedBox(height: 8),
          if (recentOrders.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Belum ada pesanan',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...recentOrders.take(5).map((order) => _buildOrderTile(order)),
        ],
      ),
    );
  }

  Widget _buildOrderTile(Map<String, dynamic> order) {
    Color statusColor;
    switch (order['status']) {
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'processing':
      case 'shipped':
        statusColor = Colors.blue;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.receipt, color: statusColor, size: 20),
      ),
      title: Text(
        '#${order['order_number'] ?? order['id']}',
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        order['buyer_name'] ?? order['buyer_email'] ?? '-',
        style: TextStyle(fontSize: 12),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _currencyFormat.format(order['total_price'] ?? 0),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          SizedBox(height: 2),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _formatStatus(order['status']),
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentUsersSection() {
    final recentUsers = List<Map<String, dynamic>>.from(
      _dashboardData!['recent_users'] ?? [],
    );

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pengguna Baru',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => context.push('/admin/users'),
                child: Text('Lihat Semua'),
              ),
            ],
          ),
          SizedBox(height: 8),
          if (recentUsers.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Belum ada pengguna baru',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...recentUsers.take(5).map((user) => _buildUserTile(user)),
        ],
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    Color roleColor;
    switch (user['role']) {
      case 'admin':
        roleColor = Colors.red;
        break;
      case 'seller':
        roleColor = Colors.orange;
        break;
      default:
        roleColor = Colors.blue;
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: roleColor.withOpacity(0.2),
        child: Text(
          (user['full_name'] ?? user['email'] ?? 'U')
              .toString()
              .substring(0, 1)
              .toUpperCase(),
          style: TextStyle(color: roleColor, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        user['full_name'] ?? user['email'] ?? '-',
        style: TextStyle(fontWeight: FontWeight.w500),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        user['email'] ?? '-',
        style: TextStyle(fontSize: 12),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: roleColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          _formatRole(user['role']),
          style: TextStyle(
            color: roleColor,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
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

  String _formatRole(String? role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'seller':
        return 'Penjual';
      case 'buyer':
        return 'Pembeli';
      default:
        return role ?? '-';
    }
  }
}
