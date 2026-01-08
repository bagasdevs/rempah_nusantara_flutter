import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _products = [];
  Map<String, dynamic> _pagination = {};

  // Filters
  String? _selectedStatus;
  String? _selectedStockStatus;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts({int offset = 0}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ApiService.getAdminProducts(
        limit: 20,
        offset: offset,
        status: _selectedStatus,
        stockStatus: _selectedStockStatus,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      setState(() {
        _products = result['products'];
        _pagination = result['pagination'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleActive(int productId, bool isActive) async {
    try {
      await ApiService.updateAdminProduct(
        productId: productId,
        isActive: isActive,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isActive ? 'Produk diaktifkan' : 'Produk dinonaktifkan',
          ),
          backgroundColor: isActive ? Colors.green : Colors.orange,
        ),
      );
      _loadProducts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _toggleFeatured(int productId, bool isFeatured) async {
    try {
      await ApiService.updateAdminProduct(
        productId: productId,
        isFeatured: isFeatured,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFeatured
                ? 'Produk dijadikan unggulan'
                : 'Produk dihapus dari unggulan',
          ),
          backgroundColor: Colors.green,
        ),
      );
      _loadProducts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _toggleApproved(
    int productId,
    bool isApproved, {
    String? reason,
  }) async {
    try {
      await ApiService.updateAdminProduct(
        productId: productId,
        isApproved: isApproved,
        rejectionReason: reason,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isApproved ? 'Produk disetujui' : 'Produk ditolak'),
          backgroundColor: isApproved ? Colors.green : Colors.orange,
        ),
      );
      _loadProducts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteProduct(int productId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Produk'),
        content: Text(
          'Apakah Anda yakin ingin menghapus produk "$name"?\n\nJika produk memiliki pesanan, hanya akan dinonaktifkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await ApiService.deleteAdminProduct(productId);
        final action = result['action'] == 'soft_delete'
            ? 'dinonaktifkan'
            : 'dihapus';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Produk berhasil $action'),
            backgroundColor: Colors.green,
          ),
        );
        _loadProducts();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRejectDialog(int productId) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tolak Produk'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Berikan alasan penolakan (opsional):'),
            SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Alasan',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _toggleApproved(
                productId,
                false,
                reason: reasonController.text.isNotEmpty
                    ? reasonController.text
                    : null,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Tolak', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Produk'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _loadProducts(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
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
              hintText: 'Cari produk...',
              prefixIcon: Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                        _loadProducts();
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
              _loadProducts();
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
                    _loadProducts();
                  },
                ),
                SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Aktif',
                  selected: _selectedStatus == 'active',
                  color: Colors.green,
                  onTap: () {
                    setState(() {
                      _selectedStatus = 'active';
                    });
                    _loadProducts();
                  },
                ),
                SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Nonaktif',
                  selected: _selectedStatus == 'inactive',
                  color: Colors.grey,
                  onTap: () {
                    setState(() {
                      _selectedStatus = 'inactive';
                    });
                    _loadProducts();
                  },
                ),
                SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Pending',
                  selected: _selectedStatus == 'pending',
                  color: Colors.orange,
                  onTap: () {
                    setState(() {
                      _selectedStatus = 'pending';
                    });
                    _loadProducts();
                  },
                ),
                SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Unggulan',
                  selected: _selectedStatus == 'featured',
                  color: Colors.purple,
                  onTap: () {
                    setState(() {
                      _selectedStatus = 'featured';
                    });
                    _loadProducts();
                  },
                ),
                SizedBox(width: 16),
                Container(width: 1, height: 24, color: Colors.grey[400]),
                SizedBox(width: 16),
                _buildFilterChip(
                  label: 'Stok Habis',
                  selected: _selectedStockStatus == 'out_of_stock',
                  color: Colors.red,
                  onTap: () {
                    setState(() {
                      _selectedStockStatus =
                          _selectedStockStatus == 'out_of_stock'
                          ? null
                          : 'out_of_stock';
                    });
                    _loadProducts();
                  },
                ),
                SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Stok Rendah',
                  selected: _selectedStockStatus == 'low_stock',
                  color: Colors.amber,
                  onTap: () {
                    setState(() {
                      _selectedStockStatus = _selectedStockStatus == 'low_stock'
                          ? null
                          : 'low_stock';
                    });
                    _loadProducts();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
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
            Text('Memuat data produk...'),
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
                onPressed: () => _loadProducts(),
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

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Tidak ada produk ditemukan',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadProducts(),
      child: ListView.builder(
        padding: EdgeInsets.all(12),
        itemCount: _products.length + (_pagination['has_more'] == true ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _products.length) {
            return _buildLoadMoreButton();
          }
          return _buildProductCard(_products[index]);
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final isActive = product['is_active'] == true;
    final isFeatured = product['is_featured'] == true;
    final isApproved = product['is_approved'] == true;
    final stock = product['stock'] ?? 0;

    Color stockColor;
    String stockLabel;
    if (stock == 0) {
      stockColor = Colors.red;
      stockLabel = 'Habis';
    } else if (stock < 10) {
      stockColor = Colors.amber;
      stockLabel = 'Rendah';
    } else {
      stockColor = Colors.green;
      stockLabel = 'Tersedia';
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showProductDetail(product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: product['image_url'] != null
                          ? Image.network(
                              product['image_url'],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Icon(Icons.image, color: Colors.grey),
                            )
                          : Icon(
                              Icons.inventory_2,
                              color: Colors.grey,
                              size: 32,
                            ),
                    ),
                  ),
                  if (!isActive)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'NONAKTIF',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (isFeatured)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.star, color: Colors.white, size: 12),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product['name'] ?? '-',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      _currencyFormat.format(product['price'] ?? 0),
                      style: TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: stockColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Stok: ${product['stock']} ($stockLabel)',
                            style: TextStyle(
                              color: stockColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        if (!isApproved)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'PENDING',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Penjual: ${product['seller_name'] ?? product['seller_email'] ?? '-'}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (product['category_name'] != null) ...[
                      SizedBox(height: 2),
                      Text(
                        'Kategori: ${product['category_name']}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
              // Actions
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                onSelected: (action) {
                  switch (action) {
                    case 'view':
                      context.push('/product/${product['id']}');
                      break;
                    case 'activate':
                      _toggleActive(product['id'], true);
                      break;
                    case 'deactivate':
                      _toggleActive(product['id'], false);
                      break;
                    case 'feature':
                      _toggleFeatured(product['id'], true);
                      break;
                    case 'unfeature':
                      _toggleFeatured(product['id'], false);
                      break;
                    case 'approve':
                      _toggleApproved(product['id'], true);
                      break;
                    case 'reject':
                      _showRejectDialog(product['id']);
                      break;
                    case 'delete':
                      _deleteProduct(product['id'], product['name'] ?? '-');
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility, size: 20),
                        SizedBox(width: 8),
                        Text('Lihat Produk'),
                      ],
                    ),
                  ),
                  PopupMenuDivider(),
                  if (isActive)
                    PopupMenuItem(
                      value: 'deactivate',
                      child: Row(
                        children: [
                          Icon(
                            Icons.visibility_off,
                            size: 20,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 8),
                          Text('Nonaktifkan'),
                        ],
                      ),
                    )
                  else
                    PopupMenuItem(
                      value: 'activate',
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 20,
                            color: Colors.green,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Aktifkan',
                            style: TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  if (isFeatured)
                    PopupMenuItem(
                      value: 'unfeature',
                      child: Row(
                        children: [
                          Icon(Icons.star_border, size: 20),
                          SizedBox(width: 8),
                          Text('Hapus Unggulan'),
                        ],
                      ),
                    )
                  else
                    PopupMenuItem(
                      value: 'feature',
                      child: Row(
                        children: [
                          Icon(Icons.star, size: 20, color: Colors.purple),
                          SizedBox(width: 8),
                          Text(
                            'Jadikan Unggulan',
                            style: TextStyle(color: Colors.purple),
                          ),
                        ],
                      ),
                    ),
                  if (!isApproved) ...[
                    PopupMenuItem(
                      value: 'approve',
                      child: Row(
                        children: [
                          Icon(Icons.thumb_up, size: 20, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Setujui',
                            style: TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'reject',
                      child: Row(
                        children: [
                          Icon(
                            Icons.thumb_down,
                            size: 20,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 8),
                          Text('Tolak', style: TextStyle(color: Colors.orange)),
                        ],
                      ),
                    ),
                  ],
                  PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Hapus', style: TextStyle(color: Colors.red)),
                      ],
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

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: ElevatedButton(
          onPressed: () {
            final currentOffset = _pagination['offset'] ?? 0;
            final limit = _pagination['limit'] ?? 20;
            _loadProducts(offset: currentOffset + limit);
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

  void _showProductDetail(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
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
              // Product image
              if (product['image_url'] != null)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      product['image_url'],
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: Icon(Icons.image, size: 64, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              SizedBox(height: 16),
              Text(
                product['name'] ?? '-',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                _currencyFormat.format(product['price'] ?? 0),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 8),
              _buildDetailRow('ID Produk', '${product['id']}'),
              _buildDetailRow('Kategori', product['category_name'] ?? '-'),
              _buildDetailRow('Stok', '${product['stock'] ?? 0}'),
              _buildDetailRow(
                'Status',
                product['is_active'] == true ? 'Aktif' : 'Nonaktif',
              ),
              _buildDetailRow(
                'Unggulan',
                product['is_featured'] == true ? 'Ya' : 'Tidak',
              ),
              _buildDetailRow(
                'Disetujui',
                product['is_approved'] == true ? 'Ya' : 'Belum',
              ),
              Divider(),
              _buildDetailRow('Penjual', product['seller_name'] ?? '-'),
              _buildDetailRow('Email Penjual', product['seller_email'] ?? '-'),
              Divider(),
              _buildDetailRow('Dibuat', _formatDate(product['created_at'])),
              _buildDetailRow('Diperbarui', _formatDate(product['updated_at'])),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/product/${product['id']}');
                      },
                      icon: Icon(Icons.visibility),
                      label: Text('Lihat Halaman'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteProduct(product['id'], product['name'] ?? '-');
                      },
                      icon: Icon(Icons.delete),
                      label: Text('Hapus'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
