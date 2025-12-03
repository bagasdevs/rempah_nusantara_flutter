import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/config/app_theme.dart';
import 'package:myapp/widgets/bottom_nav_bar.dart';
import 'package:myapp/widgets/custom_app_bar.dart';
import 'package:myapp/widgets/product_card.dart';
import 'package:myapp/widgets/category_chip.dart';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:myapp/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _productsFuture;
  late Future<List<Map<String, dynamic>>> _carouselProductsFuture;
  late Future<List<Map<String, dynamic>>> _categoriesFuture;
  late Future<List<Map<String, dynamic>>> _trendingProductsFuture;

  String _userName = 'Guest';
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _carouselProductsFuture = _fetchProducts(limit: 5);
    _categoriesFuture = _fetchCategories();
    _productsFuture = _fetchProducts();
    _trendingProductsFuture = _fetchProducts(limit: 4);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchProducts({
    int? categoryId,
    int limit = 10,
  }) async {
    try {
      return await ApiService.getProducts(
        categoryId: categoryId,
        limit: limit,
        orderBy: 'created_at',
        orderDir: 'DESC',
      );
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchCategories() async {
    try {
      return await ApiService.getCategories(limit: 6);
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  Future<void> _fetchUserProfile() async {
    if (!ApiService.isAuthenticated || ApiService.currentUserId == null) {
      return;
    }

    try {
      final profile = await ApiService.getProfile(ApiService.currentUserId!);
      if (mounted) {
        setState(() => _userName = profile['full_name'] ?? 'Guest');
      }
    } catch (e) {
      print('Error fetching profile: $e');
    }
  }

  void _onCategorySelected(int? categoryId) {
    setState(() {
      if (_selectedCategoryId == categoryId) {
        _selectedCategoryId = null;
      } else {
        _selectedCategoryId = categoryId;
      }
      _productsFuture = _fetchProducts(categoryId: _selectedCategoryId);
    });
  }

  void _handleSearch() {
    // Navigate to search screen or show search results
    context.push('/search');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomSearchAppBar(
        controller: _searchController,
        hintText: 'Cari rempah...',
        onSearchTap: _handleSearch,
        readOnly: true,
        onFilterTap: () {
          // Show filter bottom sheet
        },
      ),
      body: Stack(
        children: [
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _productsFuture = _fetchProducts(
                    categoryId: _selectedCategoryId,
                  );
                  _carouselProductsFuture = _fetchProducts(limit: 5);
                  _trendingProductsFuture = _fetchProducts(limit: 4);
                });
              },
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: AppSizes.paddingMD),
                    _buildAdCarousel(),
                    const SizedBox(height: AppSizes.paddingLG),
                    _buildCategorySection(),
                    const SizedBox(height: AppSizes.paddingLG),

                    _buildTrendingSection(),
                    const SizedBox(height: AppSizes.paddingLG),
                    _buildRecommendedSection(),
                    const SizedBox(height: 100), // Space for bottom nav
                  ],
                ),
              ),
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: BottomNavBar(currentRoute: '/'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingLG,
        vertical: AppSizes.paddingMD,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hi! $_userName 👋',
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.paddingXS),
          Text(
            'Kamu sedang mencari rempah apa?',
            style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildAdCarousel() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _carouselProductsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            height: 180,
            margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLG),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusLG),
            ),
            child: Center(
              child: Text(
                'Memuat promosi...',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          );
        }

        final products = snapshot.data!;
        return CarouselSlider.builder(
          itemCount: products.length,
          itemBuilder: (context, index, realIndex) {
            final product = products[index];
            final imageUrl = product['image_url'] as String?;

            return GestureDetector(
              onTap: () => context.push('/product/${product['id']}'),
              child: Container(
                width: MediaQuery.of(context).size.width,
                margin: const EdgeInsets.symmetric(horizontal: 5.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLG),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Background Image with overlay
                    if (imageUrl != null && imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
                        child: Stack(
                          children: [
                            Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(color: AppColors.primary);
                              },
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Content
                    Positioned(
                      bottom: AppSizes.paddingLG,
                      left: AppSizes.paddingLG,
                      right: AppSizes.paddingLG,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name'] ?? 'Produk',
                            style: AppTextStyles.heading3.copyWith(
                              color: AppColors.textWhite,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSizes.paddingXS),
                          Text(
                            'Rp ${product['price']}',
                            style: AppTextStyles.subtitle1.copyWith(
                              color: AppColors.textWhite,
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
          },
          options: CarouselOptions(
            height: 180,
            autoPlay: true,
            enlargeCenterPage: true,
            aspectRatio: 16 / 9,
            viewportFraction: 0.85,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
          ),
        );
      },
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLG),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kategori',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/categories'),
                child: Text(
                  'Lihat Semua',
                  style: AppTextStyles.subtitle2.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.paddingMD),
        SizedBox(
          height: 45,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _categoriesFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              final categories = snapshot.data!;
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingLG,
                ),
                itemCount: categories.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: AppSizes.paddingSM),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final categoryId = category['id'];
                  final isSelected = _selectedCategoryId == categoryId;

                  return CategoryChip(
                    label: category['name'],
                    isSelected: isSelected,
                    onTap: () => _onCategorySelected(categoryId),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLG),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: AppColors.secondary,
                    size: AppSizes.iconSizeMD,
                  ),
                  const SizedBox(width: AppSizes.paddingXS),
                  Text(
                    'Produk Trending',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => context.push('/products'),
                child: Text(
                  'Lihat Semua',
                  style: AppTextStyles.subtitle2.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.paddingMD),
        SizedBox(
          height: 260,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _trendingProductsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    'Belum ada produk trending',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }

              final products = snapshot.data!;
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingLG,
                ),
                itemCount: products.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: AppSizes.paddingMD),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return SizedBox(
                    width: 160,
                    child: ProductCard(
                      imageUrl: product['image_url'] ?? '',
                      name: product['name'] ?? 'Produk',
                      price: 'Rp ${product['price']}',
                      rating: '4.5',
                      onTap: () => context.push('/product/${product['id']}'),
                      onFavoriteTap: () {
                        // Add to favorites
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLG),
          child: Text(
            'Produk Rekomendasi',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.paddingMD),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _productsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(AppSizes.paddingXL),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(AppSizes.paddingXL),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: AppColors.iconGrey,
                      ),
                      const SizedBox(height: AppSizes.paddingMD),
                      Text(
                        'Belum ada produk tersedia',
                        style: AppTextStyles.body1.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final products = snapshot.data!;
            return GridView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingLG,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSizes.paddingMD,
                mainAxisSpacing: AppSizes.paddingMD,
                childAspectRatio: 0.68,
              ),
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
                    // Add to favorites
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Ditambahkan ke favorit'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMD,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}
