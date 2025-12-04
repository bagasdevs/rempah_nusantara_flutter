import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/config/app_theme.dart';
import 'package:myapp/widgets/bottom_nav_bar.dart';
import 'package:myapp/services/api_service.dart';
import 'package:myapp/utils/image_utils.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = true;
  bool _selectAll = false;
  final TextEditingController _voucherController = TextEditingController();
  String? _appliedVoucher;
  double _discountAmount = 0;
  bool _isApplyingVoucher = false;

  @override
  void initState() {
    super.initState();
    _fetchCartItems();
  }

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  Future<void> _fetchCartItems() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    if (!ApiService.isAuthenticated) {
      if (mounted) {
        setState(() {
          _cartItems = [];
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final cartData = await ApiService.getCart();
      if (mounted) {
        setState(() {
          _cartItems = List<Map<String, dynamic>>.from(
            cartData['items'] ?? [],
          ).map((item) => {...item, 'selected': false}).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching cart: $e');
      if (mounted) {
        setState(() {
          _cartItems = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateQuantity(
    int cartItemId,
    int currentQuantity,
    int stock,
  ) async {
    final newQuantity = currentQuantity + 1;
    if (newQuantity > stock) {
      _showSnackBar('Stok tidak mencukupi', isError: true);
      return;
    }

    // Optimistic UI update
    setState(() {
      final index = _cartItems.indexWhere((item) => item['id'] == cartItemId);
      if (index != -1) {
        _cartItems[index]['quantity'] = newQuantity;
      }
    });

    try {
      await ApiService.updateCartItem(
        cartItemId: cartItemId,
        quantity: newQuantity,
      );
    } catch (e) {
      print('Error updating quantity: $e');
      _fetchCartItems(); // Refresh on error
    }
  }

  Future<void> _decreaseQuantity(int cartItemId, int currentQuantity) async {
    final newQuantity = currentQuantity - 1;
    if (newQuantity < 1) {
      _deleteItem(cartItemId);
      return;
    }

    setState(() {
      final index = _cartItems.indexWhere((item) => item['id'] == cartItemId);
      if (index != -1) {
        _cartItems[index]['quantity'] = newQuantity;
      }
    });

    try {
      await ApiService.updateCartItem(
        cartItemId: cartItemId,
        quantity: newQuantity,
      );
    } catch (e) {
      print('Error decreasing quantity: $e');
      _fetchCartItems();
    }
  }

  Future<void> _deleteItem(int cartItemId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Item'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus item ini dari keranjang?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Optimistic UI update
    setState(() {
      _cartItems.removeWhere((item) => item['id'] == cartItemId);
    });

    try {
      await ApiService.removeFromCart(cartItemId);
      _showSnackBar('Item berhasil dihapus');
    } catch (e) {
      print('Error deleting item: $e');
      _showSnackBar('Gagal menghapus item', isError: true);
      _fetchCartItems();
    }
  }

  void _toggleSelectAll() {
    setState(() {
      _selectAll = !_selectAll;
      for (var item in _cartItems) {
        item['selected'] = _selectAll;
      }
    });
  }

  void _toggleItemSelection(int index) {
    setState(() {
      _cartItems[index]['selected'] = !(_cartItems[index]['selected'] ?? false);
      _selectAll = _cartItems.every((item) => item['selected'] == true);
    });
  }

  Future<void> _applyVoucher() async {
    final code = _voucherController.text.trim();
    if (code.isEmpty) {
      _showSnackBar('Masukkan kode voucher', isError: true);
      return;
    }

    setState(() => _isApplyingVoucher = true);

    try {
      // Simulate voucher validation (replace with actual API call)
      await Future.delayed(const Duration(seconds: 1));

      // Mock voucher validation
      if (code.toUpperCase() == 'REMPAH10') {
        setState(() {
          _appliedVoucher = code;
          _discountAmount = _calculateSubtotal() * 0.1; // 10% discount
          _isApplyingVoucher = false;
        });
        _showSnackBar('Voucher berhasil diterapkan!');
      } else {
        setState(() => _isApplyingVoucher = false);
        _showSnackBar('Kode voucher tidak valid', isError: true);
      }
    } catch (e) {
      setState(() => _isApplyingVoucher = false);
      _showSnackBar('Gagal menerapkan voucher', isError: true);
    }
  }

  void _removeVoucher() {
    setState(() {
      _appliedVoucher = null;
      _discountAmount = 0;
      _voucherController.clear();
    });
    _showSnackBar('Voucher dihapus');
  }

  double _calculateSubtotal() {
    double subtotal = 0;
    for (var item in _cartItems) {
      final priceValue = item['price'];
      final price = priceValue is String
          ? double.tryParse(priceValue) ?? 0.0
          : (priceValue as num?)?.toDouble() ?? 0.0;
      final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
      subtotal += price * quantity;
    }
    return subtotal;
  }

  double _calculateSelectedSubtotal() {
    double subtotal = 0;
    for (var item in _cartItems) {
      if (item['selected'] == true) {
        final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
        final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
        subtotal += price * quantity;
      }
    }
    return subtotal;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Keranjang Belanja',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: _deleteSelectedItems,
              tooltip: 'Hapus yang dipilih',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _cartItems.isEmpty
          ? _buildEmptyCart()
          : _buildCartContent(),
      bottomNavigationBar: _cartItems.isEmpty
          ? const BottomNavBar(currentRoute: '/cart')
          : null,
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text('Keranjang Anda Kosong', style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          Text(
            'Mulai belanja dan tambahkan produk\nke keranjang Anda',
            style: AppTextStyles.body2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
            label: const Text(
              'Mulai Belanja',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent() {
    final subtotal = _calculateSubtotal();
    final selectedSubtotal = _calculateSelectedSubtotal();
    final hasSelectedItems = _cartItems.any((item) => item['selected'] == true);

    return Column(
      children: [
        // Select All Section
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Checkbox(
                value: _selectAll,
                onChanged: (_) => _toggleSelectAll(),
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Pilih Semua (${_cartItems.length} item)',
                style: AppTextStyles.subtitle1,
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Cart Items List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchCartItems,
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _cartItems.length + 1,
              itemBuilder: (context, index) {
                if (index == _cartItems.length) {
                  return _buildVoucherSection();
                }
                final item = _cartItems[index];
                return _buildCartItem(item, index);
              },
            ),
          ),
        ),

        // Summary and Checkout
        _buildSummaryAndCheckout(subtotal, selectedSubtotal, hasSelectedItems),
      ],
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, int index) {
    final imageUrl = item['image_url'] as String?;
    final currentQuantity = item['quantity'] as int;
    final stock = item['stock'] as int? ?? 0;
    final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
    final isSelected = item['selected'] == true;
    final isLowStock = stock < 5;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _toggleItemSelection(index),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleItemSelection(index),
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),

                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ImageUtils.buildImage(
                    imageUrl: imageUrl,
                    productName: item['product_name'] ?? 'Produk',
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),

                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['product_name'] ?? 'Nama Produk',
                        style: AppTextStyles.subtitle1.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Stock Status
                      if (isLowStock)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Stok terbatas: $stock',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        Text('Stok: $stock', style: AppTextStyles.caption),

                      const SizedBox(height: 8),

                      // Price
                      Text(
                        'Rp ${price.toStringAsFixed(0)}',
                        style: AppTextStyles.heading4.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Quantity Control
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildQuantityControl(
                            item['id'],
                            currentQuantity,
                            stock,
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.error,
                              size: 20,
                            ),
                            onPressed: () => _deleteItem(item['id']),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityControl(int cartItemId, int quantity, int stock) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(20),
              ),
              onTap: () => _decreaseQuantity(cartItemId, quantity),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: const Icon(
                  Icons.remove,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              quantity.toString(),
              style: AppTextStyles.subtitle1.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(20),
              ),
              onTap: () => _updateQuantity(cartItemId, quantity, stock),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: const Icon(
                  Icons.add,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherSection() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_offer_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text('Kode Promo / Voucher', style: AppTextStyles.subtitle1),
            ],
          ),
          const SizedBox(height: 12),
          if (_appliedVoucher != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Voucher diterapkan: $_appliedVoucher',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Hemat Rp ${_discountAmount.toStringAsFixed(0)}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: AppColors.error,
                    ),
                    onPressed: _removeVoucher,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _voucherController,
                    decoration: InputDecoration(
                      hintText: 'Masukkan kode voucher',
                      hintStyle: AppTextStyles.body2.copyWith(
                        color: AppColors.textHint,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isApplyingVoucher ? null : _applyVoucher,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isApplyingVoucher
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Pakai',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryAndCheckout(
    double subtotal,
    double selectedSubtotal,
    bool hasSelectedItems,
  ) {
    const shippingFee = 10000.0;
    final totalBeforeDiscount = hasSelectedItems
        ? selectedSubtotal + shippingFee
        : 0;
    final discount = hasSelectedItems
        ? (_discountAmount * selectedSubtotal / subtotal)
        : 0;
    final total = totalBeforeDiscount - discount;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSummaryRow(
                  'Subtotal',
                  'Rp ${selectedSubtotal.toStringAsFixed(0)}',
                ),
                const SizedBox(height: 8),
                _buildSummaryRow(
                  'Biaya Pengiriman',
                  'Rp ${shippingFee.toStringAsFixed(0)}',
                ),
                if (discount > 0) ...[
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    'Diskon',
                    '- Rp ${discount.toStringAsFixed(0)}',
                    valueColor: AppColors.success,
                  ),
                ],
                const Divider(height: 24, thickness: 1),
                _buildSummaryRow(
                  'Total',
                  'Rp ${total.toStringAsFixed(0)}',
                  isTotal: true,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ElevatedButton(
              onPressed: hasSelectedItems
                  ? () => _proceedToCheckout(selectedSubtotal)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.textHint,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    hasSelectedItems
                        ? 'Checkout (${_cartItems.where((item) => item['selected'] == true).length} item)'
                        : 'Pilih item untuk checkout',
                    style: AppTextStyles.button,
                  ),
                ],
              ),
            ),
          ),
          const BottomNavBar(currentRoute: '/cart'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String title,
    String value, {
    bool isTotal = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: isTotal
              ? AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold)
              : AppTextStyles.body2,
        ),
        Text(
          value,
          style: isTotal
              ? AppTextStyles.heading4.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                )
              : AppTextStyles.body2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.textPrimary,
                ),
        ),
      ],
    );
  }

  void _proceedToCheckout(double selectedSubtotal) {
    final selectedItems = _cartItems
        .where((item) => item['selected'] == true)
        .toList();

    if (selectedItems.isEmpty) {
      _showSnackBar('Pilih minimal 1 item untuk checkout', isError: true);
      return;
    }

    context.push(
      '/checkout',
      extra: {
        'cartItems': selectedItems,
        'subtotal': selectedSubtotal,
        'discount': _discountAmount > 0
            ? (_discountAmount * selectedSubtotal / _calculateSubtotal())
            : 0,
        'voucher': _appliedVoucher,
      },
    );
  }

  Future<void> _deleteSelectedItems() async {
    final selectedItems = _cartItems
        .where((item) => item['selected'] == true)
        .toList();

    if (selectedItems.isEmpty) {
      _showSnackBar('Pilih item yang ingin dihapus', isError: true);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Item'),
        content: Text('Hapus ${selectedItems.length} item dari keranjang?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    for (var item in selectedItems) {
      await _deleteItem(item['id']);
    }
  }
}
