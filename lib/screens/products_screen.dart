import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/config/app_theme.dart';
import 'package:myapp/widgets/custom_app_bar.dart';
import 'package:myapp/widgets/product_card.dart';
import 'package:myapp/services/api_service.dart';
import 'package:myapp/utils/image_utils.dart';

class ProductsScreen extends StatefulWidget {
  final int? categoryId;
  final String? categoryName;
  final String? searchQuery;

  const ProductsScreen({
    super.key,
    this.categoryId,
    this.categoryName,
    this.searchQuery,
  });

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late Future<List<Map<String, dynamic>>> _productsFuture;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _sortBy = 'newest'; // newest, name, price_low, price_high
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.searchQuery ?? '';
    _searchController.text = _searchQuery;
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadProducts() {
    setState(() {
      _productsFuture = _fetchProducts();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchProducts() async {
    try {
      String orderBy = 'created_at';
      String orderDir = 'DESC';

      switch (_sortBy) {
        case 'name':
          orderBy = 'name';
          orderDir = 'ASC';
          break;
        case 'price_low':
          orderBy = 'price';
          orderDir = 'ASC';
          break;
        case 'price_high':
          orderBy = 'price';
          orderDir = 'DESC';
          break;
        case 'newest':
        default:
          orderBy = 'created_at';
          orderDir = 'DESC';
          break;
      }

      final products = await ApiService.getProducts(
        categoryId: widget.categoryId,
        orderBy: orderBy,
        orderDir: orderDir,
      );

      return products;
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _filterProducts(
    List<Map<String, dynamic>> products,
  ) {
    if (_searchQuery.isEmpty) {
      return products;
    }
    return products.where((product) {
      final name = (product['name'] as String).toLowerCase();
      final description = (product['description'] as String? ?? '')
          .toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || description.contains(query);
    }).toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppSizes.radiusLG),
            topRight: Radius.circular(AppSizes.radiusLG),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSizes.paddingMD),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSizes.paddingMD),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingLG,
              ),
              child: Row(
                children: [
                  Text('Urutkan Berdasarkan', style: AppTextStyles.heading3),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.paddingMD),
            _buildSortOption('Terbaru', 'newest'),
            _buildSortOption('Nama (A-Z)', 'name'),
            _buildSortOption('Harga Terendah', 'price_low'),
            _buildSortOption('Harga Tertinggi', 'price_high'),
            const SizedBox(height: AppSizes.paddingLG),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String title, String value) {
    final isSelected = _sortBy == value;
    return ListTile(
      leading: Radio<String>(
        value: value,
        groupValue: _sortBy,
        onChanged: (newValue) {
          setState(() {
            _sortBy = newValue!;
            _loadProducts();
          });
          Navigator.pop(context);
        },
        activeColor: AppColors.primary,
      ),
      title: Text(
        title,
        style: AppTextStyles.subtitle1.copyWith(
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      onTap: () {
        setState(() {
          _sortBy = value;
          _loadProducts();
        });
        Navigator.pop(context);
      },
    );
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'name':
        return 'Nama (A-Z)';
      case 'price_low':
        return 'Harga Terendah';
      case 'price_high':
        return 'Harga Tertinggi';
      case 'newest':
      default:
        return 'Terbaru';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.categoryName ?? 'Semua Produk';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(title: title, showBackButton: true),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingLG),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: AppTextStyles.body1,
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                hintStyle: AppTextStyles.body2.copyWith(
                  color: AppColors.textHint,
                ),
                prefixIcon: const Icon(Icons.search, color: AppColors.iconGrey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: AppColors.iconGrey,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingMD,
                  vertical: AppSizes.paddingMD,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                  borderSide: BorderSide(color: AppColors.border, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                  borderSide: BorderSide(color: AppColors.border, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),

          // Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLG),
            child: Row(
              children: [
                // Sort Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showSortOptions,
                    icon: const Icon(Icons.sort, size: 20),
                    label: Text(_getSortLabel()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingMD,
                        vertical: AppSizes.paddingSM,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.paddingSM),
                // View Toggle
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.grid_view,
                          color: _isGridView
                              ? AppColors.primary
                              : AppColors.iconGrey,
                        ),
                        onPressed: () {
                          setState(() {
                            _isGridView = true;
                          });
                        },
                      ),
                      Container(width: 1, height: 24, color: AppColors.border),
                      IconButton(
                        icon: Icon(
                          Icons.view_list,
                          color: !_isGridView
                              ? AppColors.primary
                              : AppColors.iconGrey,
                        ),
                        onPressed: () {
                          setState(() {
                            _isGridView = false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.paddingMD),

          // Products List
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: AppSizes.paddingMD),
                        Text(
                          'Gagal memuat produk',
                          style: AppTextStyles.subtitle1.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSizes.paddingSM),
                        ElevatedButton(
                          onPressed: _loadProducts,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: AppColors.iconGrey,
                        ),
                        const SizedBox(height: AppSizes.paddingMD),
                        Text(
                          'Belum ada produk',
                          style: AppTextStyles.subtitle1.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (widget.categoryId != null) ...[
                          const SizedBox(height: AppSizes.paddingSM),
                          Text(
                            'di kategori ini',
                            style: AppTextStyles.body2.copyWith(
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                final allProducts = snapshot.data!;
                final filteredProducts = _filterProducts(allProducts);

                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: AppColors.iconGrey,
                        ),
                        const SizedBox(height: AppSizes.paddingMD),
                        Text(
                          'Produk tidak ditemukan',
                          style: AppTextStyles.subtitle1.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSizes.paddingSM),
                        Text(
                          'Coba kata kunci lain',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    _loadProducts();
                  },
                  child: _isGridView
                      ? _buildGridView(filteredProducts)
                      : _buildListView(filteredProducts),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List<Map<String, dynamic>> products) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingLG),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSizes.paddingMD,
        mainAxisSpacing: AppSizes.paddingMD,
        childAspectRatio: 0.75,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          imageUrl: product['image_url'] ?? '',
          name: product['name'] ?? 'Produk',
          price: 'Rp ${product['price']}',
          rating: '4.5',
          seller: product['seller_name'],
          onTap: () => context.push('/product/${product['id']}'),
          onFavoriteTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Ditambahkan ke favorit'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> products) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.paddingLG),
      itemCount: products.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSizes.paddingMD),
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildListItem(product);
      },
    );
  }

  Widget _buildListItem(Map<String, dynamic> product) {
    return InkWell(
      onTap: () => context.push('/product/${product['id']}'),
      borderRadius: BorderRadius.circular(AppSizes.radiusMD),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusSM),
              child: Container(
                width: 80,
                height: 80,
                color: AppColors.background,
                child: ImageUtils.buildImage(
                  imageUrl: product['image_url'],
                  productName: product['name'] ?? 'Produk',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: AppSizes.paddingMD),

            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'Produk',
                    style: AppTextStyles.subtitle1,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.paddingXS),
                  if (product['seller_name'] != null)
                    Text(
                      product['seller_name'],
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: AppSizes.paddingSM),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '4.5',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Rp ${product['price']}',
                        style: AppTextStyles.subtitle1.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Favorite Button
            IconButton(
              icon: const Icon(Icons.favorite_border),
              color: AppColors.iconGrey,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Ditambahkan ke favorit'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
