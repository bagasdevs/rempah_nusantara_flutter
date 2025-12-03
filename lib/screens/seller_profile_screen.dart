import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/services/api_service.dart';

class SellerProfileScreen extends StatefulWidget {
  final String sellerId;
  const SellerProfileScreen({super.key, required this.sellerId});

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  late Future<Map<String, dynamic>> _sellerFuture;
  late Future<List<Map<String, dynamic>>> _productsFuture;

  int _totalProducts = 0;
  int _totalStock = 0;

  @override
  void initState() {
    super.initState();
    _sellerFuture = _fetchSellerProfile();
    _productsFuture = _fetchSellerProducts();
  }

  Future<Map<String, dynamic>> _fetchSellerProfile() async {
    try {
      return await ApiService.getProfile(widget.sellerId);
    } catch (e) {
      print('Error fetching seller profile: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSellerProducts() async {
    try {
      final sellerProducts = await ApiService.getProducts(
        sellerId: widget.sellerId,
        limit: 100,
        orderBy: 'created_at',
        orderDir: 'DESC',
      );

      // Hitung total produk dan stok
      int stockCount = 0;
      for (var product in sellerProducts) {
        stockCount += (product['stock'] as int?) ?? 0;
      }

      if (mounted) {
        setState(() {
          _totalProducts = sellerProducts.length;
          _totalStock = stockCount;
        });
      }

      return sellerProducts;
    } catch (e) {
      print('Error fetching seller products: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F4),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _sellerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text('Gagal memuat profil: ${snapshot.error}'),
            );
          }
          final seller = snapshot.data!;

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(context),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildSellerHeader(seller),
                    const SizedBox(height: 24),
                    _buildDashboard(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Semua Produk'),
                  ],
                ),
              ),
              _buildProductsGrid(),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
            ],
          );
        },
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      backgroundColor: const Color(0xFFFBF9F4),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF4A4A4A)),
        onPressed: () => context.pop(),
      ),
    );
  }

  Widget _buildSellerHeader(Map<String, dynamic> seller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: NetworkImage(
              seller['avatar_url'] ?? 'https://picsum.photos/200/200?random=10',
            ),
            backgroundColor: Colors.grey[200],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  seller['full_name'] ?? 'Nama Toko',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  seller['address'] ?? 'Alamat tidak tersedia',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF4D5D42).withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildDashboardItem('Produk', _totalProducts.toString()),
          _buildDashboardItem('Stok Tersedia', '${_totalStock} kg'),
        ],
      ),
    );
  }

  Widget _buildDashboardItem(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4D5D42),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
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

  Widget _buildProductsGrid() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(child: Text('Penjual ini belum memiliki produk.')),
          );
        }
        final products = snapshot.data!;
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final product = products[index];
              return _buildProductItem(context, product);
            }, childCount: products.length),
          ),
        );
      },
    );
  }

  Widget _buildProductItem(BuildContext context, Map<String, dynamic> product) {
    final imageUrl = product['image_url'];
    return GestureDetector(
      onTap: () => context.push('/product/${product['id']}'),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: (imageUrl != null && imageUrl.isNotEmpty)
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                product['name'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
