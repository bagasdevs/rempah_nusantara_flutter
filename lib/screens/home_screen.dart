import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/widgets/bottom_nav_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Map<String, dynamic>>> _productsFuture;
  String _userName = 'Guest';

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
    _productsFuture = Supabase.instance.client
        .from('products')
        .select()
        .order('created_at', ascending: false)
        .limit(10) // Ambil 10 produk terbaru sebagai contoh
        .then((data) => data as List<Map<String, dynamic>>);
  }

  Future<void> _fetchUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final data = await Supabase.instance.client
            .from('profiles')
            .select('full_name')
            .eq('id', user.id)
            .single();
        if (mounted) setState(() => _userName = data['full_name'] ?? 'Guest');
      } catch (e) {
        // Biarkan nama default jika gagal
      }
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

  Widget _buildCategoryChips() {
    final categories = ['Aromatik', 'Rimpang', 'Daun', 'Biji & Buah', 'B'];
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          bool isSelected = index == 0;
          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 16.0 : 8.0,
              right: index == categories.length - 1 ? 16.0 : 0,
            ),
            child: Chip(
              label: Text(categories[index]),
              backgroundColor: isSelected
                  ? const Color(0xFF4D5D42)
                  : const Color(0xFFFBF9F4),
              labelStyle: TextStyle(
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
        SizedBox(
          height: 240,
          child: FutureBuilder<List<Map<String, dynamic>>>(
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
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 16.0 : 8.0,
                      right: index == products.length - 1 ? 16.0 : 0,
                    ),
                    child: _buildRecommendedItem(
                      context,
                      product['image_url'],
                      product['name'],
                      'Rp ${product['price']}',
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

  Widget _buildRecommendedItem(
    BuildContext context,
    String? imageUrl,
    String name,
    String price,
  ) {
    return GestureDetector(
      onTap: () => context.push('/product'),
      child: SizedBox(
        width: 150,
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              (imageUrl != null && imageUrl.isNotEmpty)
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      height: 150,
                      width: 150,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 150,
                        width: 150,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      ),
                    )
                  : Container(
                      height: 150,
                      width: 150,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image),
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
      ),
    );
  }
}
