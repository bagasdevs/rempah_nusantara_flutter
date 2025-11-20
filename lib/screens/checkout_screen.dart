import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double subtotal;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.subtotal,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String? _shippingAddress;
  bool _isLoading = true;
  bool _isCreatingOrder = false;
  final double _shippingFee = 10000; // Biaya pengiriman dummy

  @override
  void initState() {
    super.initState();
    _fetchUserAddress();
  }

  Future<void> _fetchUserAddress() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('address') // Asumsi nama kolom alamat adalah 'address'
          .eq('id', user.id)
          .single();
      if (mounted) {
        setState(() {
          _shippingAddress = data['address'] ?? 'Alamat belum diatur';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _shippingAddress = 'Gagal memuat alamat';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createOrder() async {
    if (_shippingAddress == null || _shippingAddress == 'Alamat belum diatur') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap atur alamat pengiriman Anda.')),
      );
      return;
    }

    setState(() => _isCreatingOrder = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw 'Pengguna tidak ditemukan';

      final totalAmount = widget.subtotal + _shippingFee;

      // Panggil fungsi RPC di Supabase
      final newOrderId = await Supabase.instance.client.rpc(
        'create_order_from_cart',
        params: {
          'p_user_id': user.id,
          'p_total_amount': totalAmount,
          'p_shipping_address': _shippingAddress,
          'p_shipping_method': 'JNE REG', // Dummy method
        },
      );

      if (mounted) {
        // Navigasi ke halaman sukses
        context.go('/order-success/${newOrderId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuat pesanan: $e')));
      }
    } finally {
      if (mounted) setState(() => _isCreatingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double totalAmount = widget.subtotal + _shippingFee;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F4),
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: const Color(0xFFFBF9F4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Alamat Pengiriman'),
                  _buildAddressCard(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Ringkasan Pesanan'),
                  _buildOrderSummary(),
                  const SizedBox(height: 24),
                  _buildPaymentDetails(totalAmount),
                ],
              ),
            ),
      bottomNavigationBar: _buildCreateOrderButton(totalAmount),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildAddressCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(
          Icons.location_on_outlined,
          color: Color(0xFF4D5D42),
        ),
        title: const Text(
          'Alamat',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(_shippingAddress ?? 'Memuat alamat...'),
        trailing: TextButton(
          onPressed: () {
            // Navigasi ke halaman edit profil dan tunggu hasilnya
            context.push('/edit-profile').then((result) {
              // Jika halaman edit profil mengembalikan 'true', muat ulang alamat
              if (result == true) _fetchUserAddress();
            });
          },
          child: const Text('Ubah', style: TextStyle(color: Color(0xFF4D5D42))),
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: widget.cartItems.map((item) {
            final product = item['products'];
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product['image_url'] ?? '',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image_not_supported),
                ),
              ),
              title: Text(product['name'] ?? 'Produk'),
              subtitle: Text('Rp ${product['price'] ?? 0}'),
              trailing: Text('x${item['quantity']}'),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPaymentDetails(double totalAmount) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rincian Pembayaran',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Subtotal Produk',
              'Rp ${widget.subtotal.toStringAsFixed(0)}',
            ),
            _buildDetailRow(
              'Biaya Pengiriman',
              'Rp ${_shippingFee.toStringAsFixed(0)}',
            ),
            const Divider(height: 24),
            _buildDetailRow(
              'Total Pembayaran',
              'Rp ${totalAmount.toStringAsFixed(0)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: isTotal ? Colors.black : Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateOrderButton(double totalAmount) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: _isCreatingOrder ? null : _createOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4D5D42),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isCreatingOrder
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Buat Pesanan',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
      ),
    );
  }
}
