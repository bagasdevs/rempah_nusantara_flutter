import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/config/app_theme.dart';
import 'package:myapp/widgets/custom_app_bar.dart';
import 'package:myapp/widgets/category_chip.dart';
import 'package:myapp/services/api_service.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late Future<List<Map<String, dynamic>>> _categoriesFuture;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _fetchCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchCategories() async {
    try {
      return await ApiService.getCategories();
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _filterCategories(
    List<Map<String, dynamic>> categories,
  ) {
    if (_searchQuery.isEmpty) {
      return categories;
    }
    return categories.where((category) {
      final name = (category['name'] as String).toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _onCategoryTap(int categoryId, String categoryName) {
    // Navigate to products screen filtered by category
    context.push('/products?category=$categoryId&name=$categoryName');
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    // Kategori Rempah-Rempah
    if (name.contains('bumbu racikan') || name.contains('racikan')) {
      return Icons.restaurant;
    } else if (name.contains('herbal') || name.contains('obat')) {
      return Icons.local_pharmacy;
    } else if (name.contains('rempah bubuk') || name.contains('bubuk')) {
      return Icons.grain;
    } else if (name.contains('rempah utuh') || name.contains('utuh')) {
      return Icons.spa;
    } else if (name.contains('rempah') || name.contains('spice')) {
      return Icons.local_florist;
    } else if (name.contains('jahe') || name.contains('ginger')) {
      return Icons.eco;
    } else if (name.contains('kunyit') || name.contains('turmeric')) {
      return Icons.local_florist;
    } else if (name.contains('kayu manis') || name.contains('cinnamon')) {
      return Icons.park;
    } else if (name.contains('cengkeh') || name.contains('clove')) {
      return Icons.eco_outlined;
    } else if (name.contains('pala') || name.contains('nutmeg')) {
      return Icons.nature;
    } else if (name.contains('merica') ||
        name.contains('lada') ||
        name.contains('pepper')) {
      return Icons.circle;
    }
    return Icons.local_florist;
  }

  Color _getCategoryColor(int index) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.success,
      AppColors.info,
      AppColors.warning,
      AppColors.primaryLight,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Kategori', showBackButton: true),
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
                hintText: 'Cari kategori...',
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

          // Categories Grid
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _categoriesFuture,
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
                          'Gagal memuat kategori',
                          style: AppTextStyles.subtitle1.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSizes.paddingSM),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _categoriesFuture = _fetchCategories();
                            });
                          },
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
                          Icons.category_outlined,
                          size: 64,
                          color: AppColors.iconGrey,
                        ),
                        const SizedBox(height: AppSizes.paddingMD),
                        Text(
                          'Belum ada kategori',
                          style: AppTextStyles.subtitle1.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final allCategories = snapshot.data!;
                final filteredCategories = _filterCategories(allCategories);

                if (filteredCategories.isEmpty) {
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
                          'Kategori tidak ditemukan',
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
                    setState(() {
                      _categoriesFuture = _fetchCategories();
                    });
                  },
                  child: GridView.builder(
                    padding: const EdgeInsets.all(AppSizes.paddingLG),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppSizes.paddingMD,
                          mainAxisSpacing: AppSizes.paddingMD,
                          childAspectRatio: 1.1,
                        ),
                    itemCount: filteredCategories.length,
                    itemBuilder: (context, index) {
                      final category = filteredCategories[index];
                      final categoryId = category['id'] as int;
                      final categoryName = category['name'] as String;
                      final itemCount = category['product_count'] as int?;

                      return CategoryCard(
                        title: categoryName,
                        icon: _getCategoryIcon(categoryName),
                        color: _getCategoryColor(index),
                        itemCount: itemCount,
                        imageUrl: category['image_url'],
                        onTap: () => _onCategoryTap(categoryId, categoryName),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
