import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:myapp/config/app_theme.dart';
import 'package:myapp/services/api_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<Map<String, dynamic>> _productFuture;
  late Future<List<Map<String, dynamic>>> _relatedProductsFuture;

  bool _isAddingToCart = false;
  bool _isFavorite = false;
  int _quantity = 1;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _productFuture = _fetchProductDetails();
  }

  Future<Map<String, dynamic>> _fetchProductDetails() async {
    try {
      final response = await ApiService.getProductDetail(widget.productId);

      final categoryId = response['category_id'];
      if (categoryId != null) {
        _relatedProductsFuture = _fetchRelatedProducts(
          categoryId: categoryId,
          currentProductId: response['id'],
        );
      } else {
        _relatedProductsFuture = Future.value([]);
      }

      return response;
    } catch (e) {
      print('Error fetching product details: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRelatedProducts({
    required int categoryId,
    required int currentProductId,
  }) async {
    try {
      var response = await ApiService.getProducts(
        categoryId: categoryId,
        limit: 6,
      );

      response = response.where((p) => p['id'] != currentProductId).toList();

      if (response.isEmpty) {
        response = await ApiService.getProducts(limit: 6);
        response = response.where((p) => p['id'] != currentProductId).toList();
      }

      return response;
    } catch (e) {
      print('Error fetching related products: $e');
      return [];
    }
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    // TODO: Save to backend
  }

  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  Future<void> _addToCart(int productId) async {
    setState(() => _isAddingToCart = true);

    if (!ApiService.isAuthenticated) {
      context.push('/login');
      setState(() => _isAddingToCart = false);
      return;
    }

    try {
      await ApiService.addToCart(productId: productId, quantity: _quantity);

      if (mounted) {
        _showAddedToCartDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan ke keranjang: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingToCart = false);
      }
    }
  }

  void _showAddedToCartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: EdgeInsets.all(AppSizes.paddingLarge),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(AppSizes.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 48,
                  ),
                ),
                SizedBox(height: AppSizes.spacingMedium),
                Text(
                  'Berhasil ditambahkan!',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSizes.spacingSmall),
                Text(
                  '$_quantity item ditambahkan ke keranjang',
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _productFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => context.pop(),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.textHint,
                  ),
                  SizedBox(height: AppSizes.spacingMedium),
                  Text(
                    'Gagal memuat produk',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: AppSizes.spacingSmall),
                  Text(
                    '${snapshot.error}',
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.textHint,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final product = snapshot.data!;
        // Mock multiple images - in real app, get from API
        final List<String> images = [
          (product['image_url'] as String?) ??
              'https://via.placeholder.com/400',
          'https://via.placeholder.com/400',
          'https://via.placeholder.com/400',
        ];

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(images),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductInfo(product),
                    _buildSellerInfo(product),
                    _buildDivider(),
                    _buildDescriptionSection(product),
                    _buildDivider(),
                    _buildProductDetails(product),
                    _buildDivider(),
                    _buildReviewsSection(),
                    SizedBox(height: AppSizes.spacingMedium),
                    _buildRelatedProducts(),
                    SizedBox(height: 100), // Space for bottom bar
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(product),
        );
      },
    );
  }

  Widget _buildSliverAppBar(List<String> images) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.white,
      leading: Container(
        margin: EdgeInsets.all(AppSizes.spacingSmall),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      actions: [
        Container(
          margin: EdgeInsets.all(AppSizes.spacingSmall),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? AppColors.error : AppColors.textPrimary,
            ),
            onPressed: _toggleFavorite,
          ),
        ),
        Container(
          margin: EdgeInsets.all(AppSizes.spacingSmall),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.share, color: AppColors.textPrimary),
            onPressed: () {
              // TODO: Implement share
            },
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            CarouselSlider(
              options: CarouselOptions(
                height: 300,
                viewportFraction: 1.0,
                enableInfiniteScroll: images.length > 1,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentImageIndex = index;
                  });
                },
              ),
              items: images.map((imageUrl) {
                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                      width: MediaQuery.of(context).size.width,
                      color: Colors.white,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.background,
                            child: Icon(
                              Icons.image_not_supported,
                              size: 64,
                              color: AppColors.textHint,
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              }).toList(),
            ),
            if (images.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: images.asMap().entries.map((entry) {
                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentImageIndex == entry.key
                            ? AppColors.primary
                            : Colors.white.withOpacity(0.5),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductInfo(Map<String, dynamic> product) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(AppSizes.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product['name'] ?? 'Produk',
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppSizes.spacingSmall),
          Row(
            children: [
              Icon(Icons.star, size: 20, color: AppColors.warning),
              SizedBox(width: AppSizes.paddingXS),
              Text(
                '4.8',
                style: AppTextStyles.subtitle1.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: AppSizes.paddingXS),
              Text(
                '(156 reviews)',
                style: AppTextStyles.body1.copyWith(color: AppColors.textHint),
              ),
              const Spacer(),
              Icon(
                Icons.local_shipping_outlined,
                size: 18,
                color: AppColors.success,
              ),
              SizedBox(width: AppSizes.paddingXS),
              Text(
                'Stok: ${product['stock'] ?? 'N/A'}',
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.spacingMedium),
          Text(
            'Rp ${product['price'] ?? '0'}',
            style: AppTextStyles.heading1.copyWith(color: AppColors.primary),
          ),
          SizedBox(height: AppSizes.paddingXS),
          Text(
            'per ${product['unit'] ?? 'kg'}',
            style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerInfo(Map<String, dynamic> product) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(AppSizes.paddingMedium),
      margin: EdgeInsets.only(top: AppSizes.spacingSmall),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.background,
            child: Icon(Icons.store, color: AppColors.primary),
          ),
          SizedBox(width: AppSizes.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Petani Lokal',
                      style: AppTextStyles.subtitle1.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: AppSizes.paddingXS),
                    Icon(Icons.verified, size: 16, color: AppColors.info),
                  ],
                ),
                SizedBox(height: AppSizes.paddingXS),
                Text(
                  'Jakarta, Indonesia',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              // TODO: Navigate to seller profile
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: EdgeInsets.symmetric(
                horizontal: AppSizes.paddingMedium,
                vertical: AppSizes.paddingSmall,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
            ),
            child: const Text('Kunjungi'),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 8, color: AppColors.background);
  }

  Widget _buildDescriptionSection(Map<String, dynamic> product) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(AppSizes.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deskripsi',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppSizes.spacingMedium),
          Text(
            product['description'] ?? 'Tidak ada deskripsi.',
            style: AppTextStyles.body1.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductDetails(Map<String, dynamic> product) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(AppSizes.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detail Produk',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppSizes.spacingMedium),
          _buildDetailRow('Kategori', 'Rempah Aromatik'),
          _buildDetailRow('Berat', '${product['weight'] ?? '500'} gram'),
          _buildDetailRow('Kondisi', 'Baru'),
          _buildDetailRow('Asal', 'Indonesia'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.spacingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.body1.copyWith(color: AppColors.textHint),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body1.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(AppSizes.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ulasan (156)',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to all reviews
                },
                child: Text(
                  'Lihat Semua',
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.spacingMedium),
          // Mock review item
          _buildReviewItem(
            name: 'Budi Santoso',
            rating: 5,
            date: '2 hari lalu',
            comment:
                'Kualitas rempah sangat bagus, segar dan wangi. Pengiriman cepat!',
          ),
          Divider(height: AppSizes.spacingLarge),
          _buildReviewItem(
            name: 'Siti Aminah',
            rating: 4,
            date: '1 minggu lalu',
            comment: 'Produk sesuai deskripsi, harga terjangkau.',
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem({
    required String name,
    required int rating,
    required String date,
    required String comment,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.background,
              child: Text(
                name[0],
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: AppSizes.spacingSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    date,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  size: 16,
                  color: AppColors.warning,
                );
              }),
            ),
          ],
        ),
        SizedBox(height: AppSizes.spacingSmall),
        Text(
          comment,
          style: AppTextStyles.body1.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedProducts() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _relatedProductsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final products = snapshot.data!;
        return Container(
          color: Colors.white,
          padding: EdgeInsets.all(AppSizes.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Produk Terkait',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/products'),
                    child: Text(
                      'Lihat Semua',
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.spacingMedium),
              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: products.length,
                  separatorBuilder: (context, index) =>
                      SizedBox(width: AppSizes.spacingMedium),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _buildRelatedProductCard(product);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRelatedProductCard(Map<String, dynamic> product) {
    return GestureDetector(
      onTap: () {
        context.push('/product/${product['id']}');
      },
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppSizes.radiusMedium),
                topRight: Radius.circular(AppSizes.radiusMedium),
              ),
              child: Image.network(
                product['image_url'] ?? 'https://via.placeholder.com/140x100',
                height: 100,
                width: 140,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 100,
                    color: AppColors.background,
                    child: Icon(
                      Icons.image_not_supported,
                      color: AppColors.textHint,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppSizes.paddingSmall),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'Produk',
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: AppSizes.paddingXS),
                  Text(
                    'Rp ${product['price']}',
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(Map<String, dynamic> product) {
    return Container(
      padding: EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Quantity selector
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.textHint.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: _decrementQuantity,
                    color: AppColors.textPrimary,
                    iconSize: 20,
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingSmall,
                    ),
                    child: Text(
                      '$_quantity',
                      style: AppTextStyles.subtitle1.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _incrementQuantity,
                    color: AppColors.textPrimary,
                    iconSize: 20,
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSizes.spacingMedium),
            // Add to cart button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isAddingToCart
                    ? null
                    : () => _addToCart(product['id']),
                icon: _isAddingToCart
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.shopping_cart, size: 20),
                label: Text(
                  _isAddingToCart ? 'Menambahkan...' : 'Tambah ke Keranjang',
                  style: AppTextStyles.subtitle1.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: AppSizes.paddingMedium,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
