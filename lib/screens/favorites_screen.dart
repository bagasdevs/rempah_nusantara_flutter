import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rempah_nusantara/config/app_theme.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _isLoading = false;
  final Set<int> _selectedProducts = {};
  bool _isSelectionMode = false;

  // Mock favorite products
  final List<Map<String, dynamic>> _favoriteProducts = [
    {
      'id': 1,
      'name': 'Kayu Manis Premium',
      'price': 45000,
      'rating': 4.8,
      'reviews': 125,
      'stock': 50,
      'seller': 'Rempah Nusantara',
      'image': 'assets/images/cinnamon.jpg',
      'discount': 10,
    },
    {
      'id': 2,
      'name': 'Pala Utuh',
      'price': 35000,
      'rating': 4.7,
      'reviews': 89,
      'stock': 30,
      'seller': 'Toko Rempah Jaya',
      'image': 'assets/images/nutmeg.jpg',
    },
    {
      'id': 3,
      'name': 'Cengkeh Premium',
      'price': 55000,
      'rating': 4.9,
      'reviews': 203,
      'stock': 75,
      'seller': 'Rempah Asli',
      'image': 'assets/images/cloves.jpg',
      'discount': 15,
    },
    {
      'id': 4,
      'name': 'Lada Hitam Premium',
      'price': 52000,
      'rating': 4.6,
      'reviews': 156,
      'stock': 0,
      'seller': 'Rempah Nusantara',
      'image': 'assets/images/pepper.jpg',
    },
  ];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _refreshFavorites() async {
    setState(() => _isLoading = true);
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedProducts.clear();
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedProducts.length == _favoriteProducts.length) {
        _selectedProducts.clear();
      } else {
        _selectedProducts.clear();
        _selectedProducts.addAll(_favoriteProducts.map((p) => p['id'] as int));
      }
    });
  }

  void _removeSelected() {
    final count = _selectedProducts.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus dari Favorit'),
        content: Text('Hapus $count item dari favorit?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _favoriteProducts.removeWhere(
                  (p) => _selectedProducts.contains(p['id']),
                );
                _selectedProducts.clear();
                _isSelectionMode = false;
              });
              context.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$count item dihapus dari favorit'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text('Hapus', style: TextStyle(color: Colors.red[700])),
          ),
        ],
      ),
    );
  }

  void _addToCart(Map<String, dynamic> product) {
    // Add to cart logic (to be implemented)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} ditambahkan ke keranjang'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Lihat',
          onPressed: () => context.push('/cart'),
        ),
      ),
    );
  }

  void _removeFavorite(int id) {
    setState(() {
      _favoriteProducts.removeWhere((p) => p['id'] == id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dihapus dari favorit'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final isSelected = _selectedProducts.contains(product['id']);
    final hasDiscount = product['discount'] != null;
    final isOutOfStock = product['stock'] == 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey[200]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: _isSelectionMode
            ? () {
                setState(() {
                  if (isSelected) {
                    _selectedProducts.remove(product['id']);
                  } else {
                    _selectedProducts.add(product['id']);
                  }
                });
              }
            : () => context.push('/product/${product['id']}'),
        onLongPress: () {
          if (!_isSelectionMode) {
            setState(() {
              _isSelectionMode = true;
              _selectedProducts.add(product['id']);
            });
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selection checkbox
              if (_isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedProducts.add(product['id']);
                        } else {
                          _selectedProducts.remove(product['id']);
                        }
                      });
                    },
                    activeColor: AppColors.primary,
                  ),
                ),

              // Product image
              Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.image, color: Colors.grey[400], size: 32),
                  ),
                  if (hasDiscount)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-${product['discount']}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (isOutOfStock)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Habis',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'],
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product['seller'],
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber[700], size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${product['rating']}',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          ' (${product['reviews']})',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Rp ${product['price'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        if (!_isSelectionMode && !isOutOfStock)
                          SizedBox(
                            height: 32,
                            child: ElevatedButton(
                              onPressed: () => _addToCart(product),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Icon(
                                Icons.shopping_cart_outlined,
                                size: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Favorite button
              if (!_isSelectionMode)
                IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.red),
                  onPressed: () => _removeFavorite(product['id']),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSelectedItems = _selectedProducts.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isSelectionMode
              ? '${_selectedProducts.length} dipilih'
              : 'Favorit Saya',
          style: AppTextStyles.heading2,
        ),
        actions: [
          if (!_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: Colors.black),
              onPressed: _toggleSelectionMode,
              tooltip: 'Pilih',
            )
          else
            TextButton(
              onPressed: _toggleSelectionMode,
              child: const Text('Batal'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Selection toolbar
          if (_isSelectionMode)
            Container(
              color: AppColors.primary.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: _selectAll,
                    icon: Icon(
                      hasSelectedItems &&
                              _selectedProducts.length ==
                                  _favoriteProducts.length
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: AppColors.primary,
                    ),
                    label: Text(
                      'Pilih Semua',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                  const Spacer(),
                  if (hasSelectedItems)
                    TextButton.icon(
                      onPressed: _removeSelected,
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text(
                        'Hapus',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshFavorites,
              color: AppColors.primary,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _favoriteProducts.isEmpty
                  ? _buildEmptyState('produk', Icons.favorite_border)
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: _favoriteProducts
                          .map((product) => _buildProductCard(product))
                          .toList(),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String type, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Belum ada $type favorit',
            style: AppTextStyles.bodyLarge.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Mulai tambahkan $type ke favorit',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Jelajahi Sekarang'),
          ),
        ],
      ),
    );
  }
}
