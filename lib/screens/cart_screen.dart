import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/widgets/bottom_nav_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = true;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchCartItems();
  }

  Future<void> _fetchCartItems() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final user = supabase.auth.currentUser;
    if (user == null) {
      // Jika user tidak login, kembalikan list kosong
      if (mounted) {
        setState(() {
          _cartItems = [];
          _isLoading = false;
        });
      }
      return;
    }

    final response = await supabase
        .from('cart_items')
        .select('*, products(*)') // Join dengan tabel products
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    if (mounted) {
      setState(() {
        _cartItems = response;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateQuantity(
    int cartItemId,
    int currentQuantity,
    int stock,
  ) async {
    final newQuantity = currentQuantity + 1;
    if (newQuantity > stock) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Stok tidak mencukupi')));
      return;
    }

    // Optimistic UI update: Perbarui state lokal terlebih dahulu
    setState(() {
      final index = _cartItems.indexWhere((item) => item['id'] == cartItemId);
      if (index != -1) {
        _cartItems[index]['quantity'] = newQuantity;
      }
    });

    // Update database di latar belakang
    await supabase
        .from('cart_items')
        .update({'quantity': newQuantity})
        .eq('id', cartItemId);
  }

  Future<void> _decreaseQuantity(int cartItemId, int currentQuantity) async {
    final newQuantity = currentQuantity - 1;
    if (newQuantity < 1) {
      _deleteItem(cartItemId); // Hapus jika kuantitas menjadi 0
      return;
    }

    setState(() {
      final index = _cartItems.indexWhere((item) => item['id'] == cartItemId);
      if (index != -1) {
        _cartItems[index]['quantity'] = newQuantity;
      }
    });

    await supabase
        .from('cart_items')
        .update({'quantity': newQuantity})
        .eq('id', cartItemId);
  }

  Future<void> _deleteItem(int cartItemId) async {
    // Optimistic UI update
    setState(() {
      _cartItems.removeWhere((item) => item['id'] == cartItemId);
    });
    await supabase.from('cart_items').delete().eq('id', cartItemId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F4),
      appBar: AppBar(
        title: const Text(
          'Keranjang Saya',
          style: TextStyle(
            color: Color(0xFF4D5D42),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFFBF9F4),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
          ? _buildEmptyCart()
          : _buildCartContent(),
      bottomNavigationBar: const BottomNavBar(currentRoute: '/cart'),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Keranjang Anda masih kosong',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => context.go('/'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4D5D42),
            ),
            child: const Text(
              'Mulai Belanja',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent() {
    // Hitung total
    double subtotal = 0;
    for (var item in _cartItems) {
      final product = item['products'];
      final price = (product['price'] as num?)?.toDouble() ?? 0.0;
      final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
      subtotal += price * quantity;
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchCartItems,
            color: const Color(0xFF4D5D42),
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                final item = _cartItems[index];
                return _buildCartItem(item);
              },
            ),
          ),
        ),
        _buildSummaryAndCheckout(subtotal),
      ],
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    final product = item['products'] as Map<String, dynamic>;
    final imageUrl = product['image_url'] as String?;
    final currentQuantity = item['quantity'] as int;
    final stock = product['stock'] as int? ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: (imageUrl != null && imageUrl.isNotEmpty)
                  ? Image.network(
                      imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'Nama Produk',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${product['price']}',
                    style: const TextStyle(
                      color: Color(0xFF4D5D42),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildQuantityControl(item['id'], currentQuantity, stock),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteItem(item['id']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityControl(int cartItemId, int quantity, int stock) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 16),
            onPressed: () => _decreaseQuantity(cartItemId, quantity),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            constraints: const BoxConstraints(),
          ),
          Text(
            quantity.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            onPressed: () => _updateQuantity(cartItemId, quantity, stock),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryAndCheckout(double subtotal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal', style: TextStyle(fontSize: 16)),
              Text(
                'Rp ${subtotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_cartItems.isNotEmpty) {
                context.push(
                  '/checkout',
                  extra: {'cartItems': _cartItems, 'subtotal': subtotal},
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4D5D42),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Lanjutkan ke Checkout',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
