import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/config/app_theme.dart';
import 'package:myapp/utils/image_utils.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _isSearching = false;
  bool _isLoading = false;
  String _selectedFilter = 'All';
  List<String> _recentSearches = [];
  List<Map<String, dynamic>> _searchResults = [];

  final List<String> _popularSearches = [
    'Kunyit',
    'Jahe',
    'Lengkuas',
    'Serai',
    'Daun Salam',
    'Kayu Manis',
    'Cengkeh',
    'Pala',
  ];

  final List<String> _filters = ['All', 'Products', 'Sellers'];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    }
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _loadRecentSearches() {
    // TODO: Load from SharedPreferences
    setState(() {
      _recentSearches = ['Jahe Merah', 'Kunyit Organik', 'Lada Hitam'];
    });
  }

  void _saveToRecentSearches(String query) {
    if (query.isEmpty) return;

    setState(() {
      // Remove if already exists
      _recentSearches.remove(query);
      // Add to beginning
      _recentSearches.insert(0, query);
      // Keep only last 10
      if (_recentSearches.length > 10) {
        _recentSearches = _recentSearches.sublist(0, 10);
      }
    });
    // TODO: Save to SharedPreferences
  }

  void _clearRecentSearches() {
    setState(() {
      _recentSearches.clear();
    });
    // TODO: Clear from SharedPreferences
  }

  void _removeRecentSearch(String query) {
    setState(() {
      _recentSearches.remove(query);
    });
    // TODO: Update SharedPreferences
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearching = true;
    });

    _saveToRecentSearches(query);

    // TODO: Replace with actual API call
    await Future.delayed(const Duration(milliseconds: 800));

    // Mock search results
    final mockResults = _getMockSearchResults(query);

    if (mounted) {
      setState(() {
        _searchResults = mockResults;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getMockSearchResults(String query) {
    final allResults = [
      {
        'id': 1,
        'type': 'product',
        'name': 'Jahe Merah Premium',
        'price': 25000.0,
        'unit': 'kg',
        'image': '',
        'rating': 4.8,
        'seller': 'Tani Jaya',
        'location': 'Bogor',
      },
      {
        'id': 2,
        'type': 'product',
        'name': 'Kunyit Organik',
        'price': 18000.0,
        'unit': 'kg',
        'image': '',
        'rating': 4.7,
        'seller': 'Berkah Tani',
        'location': 'Bandung',
      },

      {
        'id': 4,
        'type': 'product',
        'name': 'Lengkuas Segar',
        'price': 22000.0,
        'unit': 'kg',
        'image': '',
        'rating': 4.6,
        'seller': 'Rempah Nusantara',
        'location': 'Magelang',
      },
    ];

    // Filter based on query
    final filtered = allResults.where((item) {
      final name = item['name'].toString().toLowerCase();
      final q = query.toLowerCase();
      return name.contains(q);
    }).toList();

    // Filter based on selected filter
    if (_selectedFilter != 'All') {
      final filterType = _selectedFilter.toLowerCase();
      return filtered.where((item) {
        if (filterType == 'products') return item['type'] == 'product';
        if (filterType == 'sellers') return item['type'] == 'seller';
        return true;
      }).toList();
    }

    return filtered;
  }

  void _onSearchSubmitted(String query) {
    _searchFocusNode.unfocus();
    _performSearch(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            if (!_isSearching) ...[
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_recentSearches.isNotEmpty) _buildRecentSearches(),
                      const SizedBox(height: AppSizes.spacingLarge),
                      _buildPopularSearches(),
                    ],
                  ),
                ),
              ),
            ] else ...[
              _buildFilterChips(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _searchResults.isEmpty
                    ? _buildEmptyState()
                    : _buildSearchResults(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => context.pop(),
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: AppSizes.spacingSmall),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                border: Border.all(
                  color: _searchFocusNode.hasFocus
                      ? AppColors.primary
                      : AppColors.border,
                ),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autofocus: widget.initialQuery == null,
                decoration: InputDecoration(
                  hintText: 'Search for spices...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _isSearching = false;
                              _searchResults = [];
                            });
                          },
                          color: AppColors.textSecondary,
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingSmall,
                    vertical: AppSizes.paddingSmall,
                  ),
                ),
                style: AppTextStyles.bodyMedium,
                textInputAction: TextInputAction.search,
                onChanged: (value) {
                  setState(() {});
                  // Optional: Implement debounced search here
                },
                onSubmitted: _onSearchSubmitted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingSmall),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSizes.spacingSmall),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return FilterChip(
            label: Text(filter),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _selectedFilter = filter;
                _performSearch(_searchController.text);
              });
            },
            labelStyle: AppTextStyles.bodyMedium.copyWith(
              color: isSelected ? AppColors.surface : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            backgroundColor: AppColors.surface,
            selectedColor: AppColors.primary,
            checkmarkColor: AppColors.surface,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingMedium,
              vertical: AppSizes.paddingSmall,
            ),
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Searches',
              style: AppTextStyles.heading4.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: _clearRecentSearches,
              child: Text(
                'Clear All',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spacingSmall),
        ...List.generate(_recentSearches.length, (index) {
          final search = _recentSearches[index];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.history, color: AppColors.textSecondary),
            title: Text(search, style: AppTextStyles.bodyMedium),
            trailing: IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => _removeRecentSearch(search),
              color: AppColors.textSecondary,
            ),
            onTap: () {
              _searchController.text = search;
              _onSearchSubmitted(search);
            },
          );
        }),
      ],
    );
  }

  Widget _buildPopularSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Popular Searches',
          style: AppTextStyles.heading4.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSizes.spacingMedium),
        Wrap(
          spacing: AppSizes.spacingSmall,
          runSpacing: AppSizes.spacingSmall,
          children: _popularSearches.map((search) {
            return InkWell(
              onTap: () {
                _searchController.text = search;
                _onSearchSubmitted(search);
              },
              borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingMedium,
                  vertical: AppSizes.paddingSmall,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.trending_up,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSizes.spacingSmall),
                    Text(search, style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        final type = result['type'];

        if (type == 'product') {
          return _buildProductResult(result);
        } else {
          return _buildSellerResult(result);
        }
      },
    );
  }

  Widget _buildProductResult(Map<String, dynamic> product) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.spacingMedium),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => context.push('/product/${product['id']}'),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                child: ImageUtils.buildImage(
                  imageUrl: product['image'],
                  productName: product['name'],
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
              ),
              const SizedBox(width: AppSizes.spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'],
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSizes.spacingSmall),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 16,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product['rating'].toString(),
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(width: AppSizes.spacingSmall),
                        Text(
                          '• ${product['location']}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.spacingSmall),
                    Text(
                      'Rp ${product['price'].toStringAsFixed(0)}/${product['unit']}',
                      style: AppTextStyles.bodyLarge.copyWith(
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
      ),
    );
  }

  Widget _buildSellerResult(Map<String, dynamic> seller) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.spacingMedium),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to seller profile
        },
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          child: Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(seller['image']),
              ),
              const SizedBox(width: AppSizes.spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      seller['name'],
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacingSmall),
                    Text(
                      seller['location'],
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            Text(
              'No Results Found',
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.spacingSmall),
            Text(
              'Try searching with different keywords',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
