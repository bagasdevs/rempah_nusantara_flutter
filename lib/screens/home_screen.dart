import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/widgets/bottom_nav_bar.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:myapp/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Map<String, dynamic>>> _productsFuture;
  late Future<List<Map<String, dynamic>>>
  _carouselProductsFuture; // Future baru untuk carousel
  late Future<List<Map<String, dynamic>>> _categoriesFuture;
  String _userName = 'Guest';
  int? _selectedCategoryId; // State untuk menyimpan ID kategori yang dipilih

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F4),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  _buildAdCarousel(),
                  _buildCategoryChips(),
                  _buildRecommendedSection(context),
                  const SizedBox(height: 100),
                ], // Padding for floating nav bar
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

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _carouselProductsFuture = _fetchProducts(
      limit: 5,
    ); // Ambil 5 produk untuk carousel
    _categoriesFuture = _fetchCategories();
    _productsFuture = _fetchProducts(); // Ambil semua produk saat awal
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
      return await ApiService.getCategories(limit: 4);
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
      // Biarkan nama default jika gagal
    }
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi! $_userName',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A4A4A),
                    ),
                  ),
                  const Text(
                    'kamu Sedang Mencari Rempah Apa?',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_none_outlined,
              size: 30,
              color: Color(0xFF4D5D42),
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search, size: 30, color: Color(0xFF4D5D42)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAdCarousel() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _carouselProductsFuture, // Gunakan future khusus carousel
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text('Memuat iklan...')),
          );
        }
        final products = snapshot.data!;
        return CarouselSlider.builder(
          itemCount: products.length,
          itemBuilder: (context, index, realIndex) {
            final product = products[index];
            final imageUrl = product['image_url'] as String?;
            return Builder(
              builder: (BuildContext context) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 5.0,
                    vertical: 20.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(15),
                    image: (imageUrl != null && imageUrl.isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: (imageUrl == null || imageUrl.isEmpty)
                      ? const Center(child: Text('Gambar tidak tersedia'))
                      : null,
                );
              },
            );
          },
          options: CarouselOptions(
            height: 200,
            autoPlay: true,
            enlargeCenterPage: true,
            aspectRatio: 16 / 9,
            viewportFraction: 0.8,
          ),
        );
      },
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 50,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final categories = snapshot.data!;
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final categoryId = category['id'];
              final bool isSelected = _selectedCategoryId == categoryId;

              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 16.0 : 8.0,
                  right: index == categories.length - 1 ? 16.0 : 0,
                ),
                child: ChoiceChip(
                  labelPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                  padding: EdgeInsets.zero,
                  label: Text(category['name']),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (isSelected) {
                        _selectedCategoryId =
                            null; // Batalkan pilihan jika diklik lagi
                      } else {
                        _selectedCategoryId = categoryId; // Pilih kategori baru
                      }
                      // Ambil ulang produk dengan filter yang baru
                      _productsFuture = _fetchProducts(
                        categoryId: _selectedCategoryId,
                      );
                    });
                  },
                  backgroundColor: const Color(0xFFFBF9F4),
                  selectedColor: const Color(0xFF4D5D42),
                  labelStyle: TextStyle(
                    fontSize: 13, // Perkecil font
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF4D5D42)
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4A4A4A),
        ),
      ),
    );
  }

  Widget _buildRecommendedSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Produk Rekomendasi'),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _productsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return const Center(child: Text('Belum ada produk tersedia.'));
            }
            final products = snapshot.data!;
            return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.7, // Sesuaikan rasio ini jika perlu
              ),
              itemBuilder: (context, index) {
                final product = products[index];
                return _buildRecommendedItem(
                  context,
                  product['image_url'],
                  product['name'],
                  'Rp ${product['price']}',
                  productId: product['id'],
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecommendedItem(
    BuildContext context,
    String? imageUrl,
    String name,
    String price, {
    required int productId,
  }) {
    return GestureDetector(
      onTap: () => context.push('/product/$productId'),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: (imageUrl != null && imageUrl.isNotEmpty)
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF4A4A4A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    price,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
