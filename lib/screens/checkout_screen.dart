import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rempah_nusantara/config/app_theme.dart';
import 'package:rempah_nusantara/services/api_service.dart';
import 'package:rempah_nusantara/services/payment_service.dart';
import 'package:rempah_nusantara/widgets/checkout_stepper.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double subtotal;
  final double discount;
  final String? voucher;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.subtotal,
    this.discount = 0,
    this.voucher,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1: Address
  int? _selectedAddressId;
  Map<String, dynamic>? _selectedAddressData;
  List<Map<String, dynamic>> _addresses = [];
  bool _isLoadingAddresses = true;

  // Step 2: Shipping
  String _selectedShippingMethod = 'REGULAR';
  final List<Map<String, dynamic>> _shippingMethods = [
    {
      'id': 'REGULAR',
      'name': 'Reguler',
      'description': '3-5 hari kerja',
      'cost': 10000.0,
      'icon': Icons.local_shipping,
    },
    {
      'id': 'EXPRESS',
      'name': 'Express',
      'description': '1-2 hari kerja',
      'cost': 25000.0,
      'icon': Icons.electric_bolt,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    print('🔄 [CHECKOUT] Starting to load addresses...');
    setState(() => _isLoadingAddresses = true);

    try {
      print('🔐 [CHECKOUT] isAuthenticated: ${ApiService.isAuthenticated}');

      if (ApiService.isAuthenticated) {
        print('📡 [CHECKOUT] Calling API to get addresses...');
        final addresses = await ApiService.getAddresses();

        print('✅ [CHECKOUT] Received ${addresses.length} addresses');
        print('📦 [CHECKOUT] Addresses data: $addresses');

        setState(() {
          _addresses = addresses;

          if (_addresses.isNotEmpty) {
            print('🔍 [CHECKOUT] Looking for default address...');
            final defaultAddress = _addresses.firstWhere(
              (addr) => addr['is_default'] == true,
              orElse: () => _addresses.first,
            );
            _selectedAddressId = defaultAddress['id'];
            _selectedAddressData = defaultAddress;
            print('✓ [CHECKOUT] Selected address ID: $_selectedAddressId');
          } else {
            print('⚠️ [CHECKOUT] No addresses found!');
          }
        });
      } else {
        print('❌ [CHECKOUT] User not authenticated!');
      }
    } catch (e) {
      print('❌ [CHECKOUT] Error loading addresses: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat alamat: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingAddresses = false);
      }
      print(
        '🏁 [CHECKOUT] Finished loading addresses. Total: ${_addresses.length}',
      );
    }
  }

  void _nextStep() {
    if (_currentStep < 1) {
      if (_validateCurrentStep()) {
        setState(() => _currentStep++);
        _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      if (_selectedAddressId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pilih alamat pengiriman terlebih dahulu'),
          ),
        );
        return false;
      }
    }
    return true;
  }

  double get _shippingCost {
    final method = _shippingMethods.firstWhere(
      (m) => m['id'] == _selectedShippingMethod,
      orElse: () => _shippingMethods[0],
    );
    return method['cost'] as double;
  }

  double get _total => widget.subtotal - widget.discount + _shippingCost;

  Future<void> _processCheckout() async {
    if (!_validateCurrentStep()) return;

    setState(() => _isLoading = true);

    try {
      // Create order first
      final orderData = await ApiService.createOrderFromCart(
        totalAmount: _total,
        shippingFee: _shippingCost,
        shippingAddress: _selectedAddressData!['address'],
        paymentMethod: 'MIDTRANS',
      );

      final orderId = orderData['order']['id'];

      // Get user data for customer info
      final userData = await ApiService.getCurrentUser();
      print('📦 [CHECKOUT] User data response: $userData');

      // Handle different possible response structures
      final user = userData['data'] ?? {};
      final userMetadata = user['user_metadata'] ?? {};
      print('👤 [CHECKOUT] User object: $user');
      print('📋 [CHECKOUT] User metadata: $userMetadata');

      // Prepare items for Midtrans
      final items = widget.cartItems.map((item) {
        return {
          'id': item['product_id'].toString(),
          'name': item['product_name'],
          'price': (double.tryParse(item['price']?.toString() ?? '0') ?? 0.0)
              .toInt(),
          'quantity': item['quantity'],
        };
      }).toList();

      // Process payment with Midtrans
      final paymentResult = await PaymentService.processPayment(
        context: context,
        orderId: orderId,
        totalAmount: _total,
        items: items,
        customer: {
          'name':
              userMetadata['full_name'] ??
              user['fullname'] ??
              user['full_name'] ??
              user['username'] ??
              user['name'] ??
              'User',
          'email': user['email'] ?? 'user@example.com',
          'phone':
              userMetadata['mobile_number'] ?? user['phone'] ?? '08123456789',
        },
        shippingAddress: _selectedAddressData,
        shippingCost: _shippingCost,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        // Check payment status from response
        final paymentStatus = paymentResult['payment_status'] ?? 'unknown';
        final isSuccess =
            paymentStatus == 'paid' || paymentStatus == 'settlement';
        final isPending = paymentStatus == 'pending';

        if (isSuccess) {
          // Payment success
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pembayaran berhasil! Pesanan sedang diproses.'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to order detail
          context.go('/orders');
        } else if (isPending) {
          // Payment pending (web platform - opened in new tab)
          // Show dialog with instructions
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.payment, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Pembayaran Dibuka'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halaman pembayaran Midtrans telah dibuka di tab/window baru.',
                    style: AppTextStyles.body1,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Langkah selanjutnya:',
                    style: AppTextStyles.body1.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildInstructionItem(
                    '1',
                    'Selesaikan pembayaran di tab yang terbuka',
                  ),
                  _buildInstructionItem(
                    '2',
                    'Setelah selesai, kembali ke halaman ini',
                  ),
                  _buildInstructionItem(
                    '3',
                    'Status pesanan akan otomatis terupdate dalam beberapa saat',
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Anda dapat melihat status pesanan di halaman "Pesanan Saya"',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go('/');
                  },
                  child: Text('Kembali ke Beranda'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go('/order-status/$orderId');
                  },
                  child: Text('Lihat Status Pesanan'),
                ),
              ],
            ),
          );
        } else {
          // Payment failed or cancelled
          final message = paymentStatus == 'cancelled'
              ? 'Pembayaran dibatalkan.'
              : 'Pembayaran gagal. Silakan coba lagi.';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e, stackTrace) {
      print('❌ [CHECKOUT] Error during checkout: $e');
      print('📍 [CHECKOUT] Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          CheckoutStepper(
            currentStep: _currentStep,
            steps: const ['Alamat', 'Pengiriman'],
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [_buildAddressStep(), _buildShippingStep()],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTextStyles.body2)),
        ],
      ),
    );
  }

  Widget _buildAddressStep() {
    if (_isLoadingAddresses) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_addresses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text('Belum ada alamat', style: AppTextStyles.heading3),
            const SizedBox(height: 8),
            Text(
              'Tambahkan alamat pengiriman terlebih dahulu',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to address management
                context.push('/address').then((_) => _loadAddresses());
              },
              icon: const Icon(Icons.add),
              label: const Text('Tambah Alamat'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pilih Alamat Pengiriman', style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          Text(
            'Pilih alamat tujuan pengiriman pesanan Anda',
            style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ..._addresses.map((address) => _buildAddressCard(address)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              context.push('/address').then((_) => _loadAddresses());
            },
            icon: const Icon(Icons.add),
            label: const Text('Tambah Alamat Baru'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> address) {
    final isSelected = _selectedAddressId == address['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _selectedAddressId = address['id'];
            _selectedAddressData = address;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Radio<int>(
                value: address['id'],
                groupValue: _selectedAddressId,
                onChanged: (value) {
                  setState(() {
                    _selectedAddressId = value;
                    _selectedAddressData = address;
                  });
                },
                activeColor: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            address['label'] ?? 'Alamat',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (address['is_default'] == true) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Utama',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      address['recipient_name'] ?? '',
                      style: AppTextStyles.subtitle1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(address['phone'] ?? '', style: AppTextStyles.body2),
                    const SizedBox(height: 4),
                    Text(
                      '${address['address'] ?? ''}${address['city'] != null ? ', ${address['city']}' : ''}${address['postal_code'] != null ? ' ${address['postal_code']}' : ''}',
                      style: AppTextStyles.body2.copyWith(
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

  Widget _buildShippingStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pilih Metode Pengiriman', style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          Text(
            'Pilih jasa pengiriman yang Anda inginkan',
            style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ..._shippingMethods.map((method) => _buildShippingCard(method)),
          const SizedBox(height: 24),
          _buildOrderSummary(),
        ],
      ),
    );
  }

  Widget _buildShippingCard(Map<String, dynamic> method) {
    final isSelected = _selectedShippingMethod == method['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() => _selectedShippingMethod = method['id']);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Radio<String>(
                value: method['id'],
                groupValue: _selectedShippingMethod,
                onChanged: (value) {
                  setState(() => _selectedShippingMethod = value!);
                },
                activeColor: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Icon(
                method['icon'] as IconData,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method['name'],
                      style: AppTextStyles.subtitle1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      method['description'],
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Rp ${(method['cost'] as double).toStringAsFixed(0)}',
                style: AppTextStyles.subtitle1.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ringkasan Pesanan', style: AppTextStyles.heading3),
          const SizedBox(height: 16),
          _buildSummaryRow('Subtotal', widget.subtotal),
          if (widget.discount > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryRow('Diskon', -widget.discount, isDiscount: true),
          ],
          const SizedBox(height: 8),
          _buildSummaryRow('Ongkir', _shippingCost),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: AppTextStyles.heading3),
              Text(
                'Rp ${_total.toStringAsFixed(0)}',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.body1),
        Text(
          'Rp ${amount.abs().toStringAsFixed(0)}',
          style: AppTextStyles.body1.copyWith(
            fontWeight: FontWeight.w600,
            color: isDiscount ? Colors.green : null,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _previousStep,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text('Kembali'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: _currentStep == 0 ? 1 : 2,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : (_currentStep < 1 ? _nextStep : _processCheckout),
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 48)),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(_currentStep < 1 ? 'Lanjutkan' : 'Bayar Sekarang'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
