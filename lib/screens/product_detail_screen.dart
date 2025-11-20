import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  @override
  void initState() {
    super.initState();
    _productFuture = _fetchProductDetails();
  }

  Future<Map<String, dynamic>> _fetchProductDetails() async {
    final response = await Supabase.instance.client
        .from('products')
        .select(
          '*, profiles:seller_id(*)',
        ) // Join profiles melalui kolom seller_id
        .eq('id', widget.productId)
        .single();

    final categoryId = response['category_id'];
    if (categoryId != null) {
      // Setelah mendapatkan detail produk, ambil produk terkait
      _relatedProductsFuture = _fetchRelatedProducts(
        categoryId: categoryId,
        currentProductId: response['id'],
      );
    } else {
      // Jika tidak ada kategori, kembalikan daftar kosong untuk produk terkait.
      _relatedProductsFuture = Future.value([]);
    }

    return response;
  }

  Future<List<Map<String, dynamic>>> _fetchRelatedProducts({
    required int categoryId,
    required int currentProductId,
  }) async {
    // Coba ambil produk dari kategori yang sama, kecuali produk saat ini
    var response = await Supabase.instance.client
        .from('products')
        .select()
        .eq('category_id', categoryId)
        .neq(
          'id',
          currentProductId,
        ) // Jangan tampilkan produk yang sedang dilihat
        .limit(5); // Batasi 5 produk terkait

    // Jika tidak ada produk terkait di kategori yang sama, ambil produk lain secara acak
    if (response.isEmpty) {
      response = await Supabase.instance.client
          .from('products')
          .select()
          .neq('id', currentProductId) // Tetap jangan tampilkan produk saat ini
          .limit(5);
    }

    return response;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _productFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(), // AppBar kosong agar ada tombol kembali
            body: Center(child: Text('Gagal memuat produk: ${snapshot.error}')),
          );
        }
        final product = snapshot.data!;
        return Scaffold(
          backgroundColor: const Color(0xFFFBF9F4),
          body: Stack(
            children: [
              CustomScrollView(
                // Beri padding di bawah agar item terakhir tidak tertutup tombol
                slivers: [
                  _buildSliverAppBar(context, product),
                  _buildContentSliver(product),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _buildBottomBar(context, product),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddedToCartDialog() {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Pengguna tidak bisa menutup dengan tap di luar
      builder: (BuildContext context) {
        // Otomatis tutup dialog setelah 1.5 detik
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });

        return const Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Color(0xFF4D5D42),
                child: Icon(Icons.check, color: Colors.white, size: 40),
              ),
              SizedBox(height: 16),
              Text(
                'Berhasil ditambahkan!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addToCart(int productId) async {
    setState(() => _isAddingToCart = true);

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      context.push('/login');
      setState(() => _isAddingToCart = false);
      return;
    }

    try {
      // Cek apakah produk sudah ada di keranjang
      final existingItem = await supabase
          .from('cart_items')
          .select('id, quantity')
          .eq('user_id', user.id)
          .eq('product_id', productId)
          .maybeSingle();

      if (existingItem != null) {
        // Jika sudah ada, update quantity
        await supabase
            .from('cart_items')
            .update({'quantity': (existingItem['quantity'] as int) + 1})
            .eq('id', existingItem['id']);
      } else {
        // Jika belum ada, insert item baru
        await supabase.from('cart_items').insert({
          'user_id': user.id,
          'product_id': productId,
          'quantity': 1,
        });
      }

      _showAddedToCartDialog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan ke keranjang: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isAddingToCart = false);
      }
    }
  }

  Widget _buildBottomBar(BuildContext context, Map<String, dynamic> product) {
    // Menggunakan Container dengan gradient agar tidak terlalu polos
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ElevatedButton.icon(
        onPressed: _isAddingToCart ? null : () => _addToCart(product['id']),
        icon: _isAddingToCart
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.add_shopping_cart, color: Colors.white),
        label: Text(
          _isAddingToCart ? 'Menambahkan...' : 'Tambah ke Keranjang',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4D5D42),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // Helper widget untuk membungkus konten agar lebih rapi
  Widget _buildContentSliver(Map<String, dynamic> product) {
    return SliverList(
      delegate: SliverChildListDelegate([
        _buildProductImage(product), // Gambar utama
        _buildPrimaryInfo(product), // Info Nama & Harga
        _buildFarmerInfo(context, product), // Info Penjual
        const SizedBox(height: 24),
        _buildInfoCard(
          children: [
            _buildDescriptionSection(product),
            _buildDetailsSection(product),
          ],
        ),
        _buildRelatedProductsSection(context),
      ]),
    );
  }

  SliverAppBar _buildSliverAppBar(
    BuildContext context,
    Map<String, dynamic> product,
  ) {
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

  Widget _buildProductImage(Map<String, dynamic> product) {
    final imageUrl = product['image_url'] as String?;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        child: Stack(
          alignment: Alignment.center,
          children: [
            (imageUrl != null && imageUrl.isNotEmpty)
                ? Image.network(
                    imageUrl,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 250,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 60,
                      color: Colors.grey,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryInfo(Map<String, dynamic> product) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product['name'],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A4A4A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rp ${product['price']} / kg',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4D5D42),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmerInfo(BuildContext context, Map<String, dynamic> product) {
    // Ambil data profil penjual dari hasil join
    final sellerProfile =
        product['profiles']
            as Map<String, dynamic>?; // Nama relasi sekarang 'profiles'
    final sellerId = sellerProfile?['id'];
    final sellerName =
        sellerProfile?['full_name'] ?? 'Nama Penjual Tidak Tersedia';

    return GestureDetector(
      onTap: () {
        if (sellerId != null) context.push('/seller-profile/$sellerId');
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: ListTile(
          leading: const CircleAvatar(
            radius: 25,
            backgroundImage: NetworkImage(
              'https://picsum.photos/100/100?random=5',
            ),
          ),
          title: Text(
            sellerName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A4A4A),
            ),
          ),
          subtitle: const Text('Petani', style: TextStyle(color: Colors.grey)),
          trailing: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label: const Text('Chat'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4D5D42),
              side: const BorderSide(color: Color(0xFF4D5D42)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDetailsSection(Map<String, dynamic> product) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A4A4A),
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Harga', 'Rp ${product['price']} / kg'),
          _buildDetailRow('Penjual', product['seller_name'] ?? 'N/A'),
          _buildDetailRow('Kualitas', 'Premium Grade'), // Dummy data
          _buildDetailRow('Ketersediaan', '${product['stock']} kg'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 16, color: Color(0xFF4A4A4A)),
          children: [
            TextSpan(
              text: '$title: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection(Map<String, dynamic> product) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Deskripsi',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A4A4A),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, thickness: 1), // Garis pemisah
          const SizedBox(height: 8),
          Text(
            product['description'] ?? 'Tidak ada deskripsi untuk produk ini.',
            style: TextStyle(fontSize: 16, color: Colors.black54, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedProductsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            'Produk Terkait',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A4A4A),
            ),
          ),
        ),
        SizedBox(
          height: 240,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _relatedProductsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Tidak ada produk terkait.'));
              }
              final relatedProducts = snapshot.data!;
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: relatedProducts.length,
                itemBuilder: (context, index) {
                  final product = relatedProducts[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 16.0 : 8.0,
                      right: index == relatedProducts.length - 1 ? 16.0 : 0,
                    ),
                    child: _buildRelatedItem(
                      context,
                      product['image_url'],
                      product['name'],
                      'Rp ${product['price']}',
                      product['id'],
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

  Widget _buildRelatedItem(
    BuildContext context,
    String? imageUrl,
    String name,
    String price,
    int productId,
  ) {
    return GestureDetector(
      onTap: () => context.push('/product/$productId'),
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
                    )
                  : Container(
                      height: 150,
                      width: 150,
                      color: Colors.grey[200],
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
