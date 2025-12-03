import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/config/app_theme.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  bool _isLoading = false;

  // Mock addresses data
  final List<Map<String, dynamic>> _addresses = [
    {
      'id': 1,
      'label': 'Rumah',
      'recipientName': 'Ahmad Hidayat',
      'phone': '081234567890',
      'address': 'Jl. Merdeka No. 123',
      'district': 'Menteng',
      'city': 'Jakarta Pusat',
      'province': 'DKI Jakarta',
      'postalCode': '10110',
      'isDefault': true,
      'notes': 'Dekat dengan Taman Suropati',
    },
    {
      'id': 2,
      'label': 'Kantor',
      'recipientName': 'Ahmad Hidayat',
      'phone': '081234567890',
      'address': 'Jl. Sudirman Kav. 52-53',
      'district': 'Senayan',
      'city': 'Jakarta Selatan',
      'province': 'DKI Jakarta',
      'postalCode': '12190',
      'isDefault': false,
      'notes': 'Gedung Tower A Lantai 15',
    },
    {
      'id': 3,
      'label': 'Rumah Orang Tua',
      'recipientName': 'Siti Aminah',
      'phone': '082345678901',
      'address': 'Jl. Gatot Subroto No. 45',
      'district': 'Kebayoran Baru',
      'city': 'Jakarta Selatan',
      'province': 'DKI Jakarta',
      'postalCode': '12950',
      'isDefault': false,
      'notes': '',
    },
  ];

  Future<void> _refreshAddresses() async {
    setState(() => _isLoading = true);
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
  }

  void _setDefaultAddress(int id) {
    setState(() {
      for (var address in _addresses) {
        address['isDefault'] = address['id'] == id;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alamat utama berhasil diubah'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _editAddress(Map<String, dynamic> address) {
    _showAddressForm(address: address);
  }

  void _deleteAddress(int id) {
    final address = _addresses.firstWhere((a) => a['id'] == id);

    if (address['isDefault']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat menghapus alamat utama'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Alamat'),
        content: const Text('Apakah Anda yakin ingin menghapus alamat ini?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _addresses.removeWhere((a) => a['id'] == id);
              });
              context.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Alamat berhasil dihapus'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text('Hapus', style: TextStyle(color: Colors.red[700])),
          ),
        ],
      ),
    );
  }

  void _showAddressForm({Map<String, dynamic>? address}) {
    final isEdit = address != null;
    final labelController = TextEditingController(
      text: address?['label'] ?? '',
    );
    final nameController = TextEditingController(
      text: address?['recipientName'] ?? '',
    );
    final phoneController = TextEditingController(
      text: address?['phone'] ?? '',
    );
    final addressController = TextEditingController(
      text: address?['address'] ?? '',
    );
    final districtController = TextEditingController(
      text: address?['district'] ?? '',
    );
    final cityController = TextEditingController(text: address?['city'] ?? '');
    final provinceController = TextEditingController(
      text: address?['province'] ?? '',
    );
    final postalCodeController = TextEditingController(
      text: address?['postalCode'] ?? '',
    );
    final notesController = TextEditingController(
      text: address?['notes'] ?? '',
    );
    bool isDefault = address?['isDefault'] ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEdit ? 'Edit Alamat' : 'Tambah Alamat',
                          style: AppTextStyles.heading2,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => context.pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),

                  // Form
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        TextField(
                          controller: labelController,
                          decoration: InputDecoration(
                            labelText: 'Label Alamat',
                            hintText: 'Rumah, Kantor, dll',
                            prefixIcon: const Icon(Icons.label_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: 'Nama Penerima',
                            hintText: 'Nama lengkap penerima',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Nomor Telepon',
                            hintText: '08xxxxxxxxxx',
                            prefixIcon: const Icon(Icons.phone_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: addressController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Alamat Lengkap',
                            hintText: 'Jalan, nomor rumah, dll',
                            prefixIcon: const Icon(Icons.location_on_outlined),
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: districtController,
                                decoration: InputDecoration(
                                  labelText: 'Kecamatan',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: postalCodeController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Kode Pos',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: cityController,
                          decoration: InputDecoration(
                            labelText: 'Kota/Kabupaten',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: provinceController,
                          decoration: InputDecoration(
                            labelText: 'Provinsi',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: notesController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Catatan (Opsional)',
                            hintText: 'Patokan atau detail tambahan',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isDefault,
                                onChanged: (value) {
                                  setModalState(() {
                                    isDefault = value ?? false;
                                  });
                                },
                                activeColor: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Jadikan Alamat Utama',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Alamat ini akan dipilih secara otomatis',
                                      style: AppTextStyles.caption.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // Validate and save
                              if (labelController.text.isEmpty ||
                                  nameController.text.isEmpty ||
                                  phoneController.text.isEmpty ||
                                  addressController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Mohon lengkapi semua field yang wajib diisi',
                                    ),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }

                              setState(() {
                                if (isEdit) {
                                  // Update existing address
                                  final index = _addresses.indexWhere(
                                    (a) => a['id'] == address['id'],
                                  );
                                  _addresses[index] = {
                                    'id': address['id'],
                                    'label': labelController.text,
                                    'recipientName': nameController.text,
                                    'phone': phoneController.text,
                                    'address': addressController.text,
                                    'district': districtController.text,
                                    'city': cityController.text,
                                    'province': provinceController.text,
                                    'postalCode': postalCodeController.text,
                                    'notes': notesController.text,
                                    'isDefault': isDefault,
                                  };

                                  if (isDefault) {
                                    for (var addr in _addresses) {
                                      if (addr['id'] != address['id']) {
                                        addr['isDefault'] = false;
                                      }
                                    }
                                  }
                                } else {
                                  // Add new address
                                  final newId = _addresses.isEmpty
                                      ? 1
                                      : _addresses
                                                .map((a) => a['id'] as int)
                                                .reduce(
                                                  (a, b) => a > b ? a : b,
                                                ) +
                                            1;

                                  if (isDefault) {
                                    for (var addr in _addresses) {
                                      addr['isDefault'] = false;
                                    }
                                  }

                                  _addresses.add({
                                    'id': newId,
                                    'label': labelController.text,
                                    'recipientName': nameController.text,
                                    'phone': phoneController.text,
                                    'address': addressController.text,
                                    'district': districtController.text,
                                    'city': cityController.text,
                                    'province': provinceController.text,
                                    'postalCode': postalCodeController.text,
                                    'notes': notesController.text,
                                    'isDefault': isDefault,
                                  });
                                }
                              });

                              context.pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEdit
                                        ? 'Alamat berhasil diperbarui'
                                        : 'Alamat berhasil ditambahkan',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              isEdit ? 'Simpan Perubahan' : 'Tambah Alamat',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> address) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: address['isDefault'] ? AppColors.primary : Colors.grey[200]!,
          width: address['isDefault'] ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with label and default badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: address['isDefault']
                          ? AppColors.primary
                          : Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      address['label'],
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: address['isDefault']
                            ? AppColors.primary
                            : Colors.black,
                      ),
                    ),
                    if (address['isDefault']) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'UTAMA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                PopupMenuButton(
                  icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (context) => [
                    if (!address['isDefault'])
                      PopupMenuItem(
                        child: Row(
                          children: [
                            Icon(
                              Icons.push_pin_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Text('Jadikan Utama'),
                          ],
                        ),
                        onTap: () => _setDefaultAddress(address['id']),
                      ),
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            color: Colors.blue,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Text('Edit'),
                        ],
                      ),
                      onTap: () {
                        // Delay to allow menu to close
                        Future.delayed(
                          Duration.zero,
                          () => _editAddress(address),
                        );
                      },
                    ),
                    if (!address['isDefault'])
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Text('Hapus'),
                          ],
                        ),
                        onTap: () {
                          Future.delayed(
                            Duration.zero,
                            () => _deleteAddress(address['id']),
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Recipient info
            Text(
              address['recipientName'],
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.phone_outlined, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  address['phone'],
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Address details
            Text(address['address'], style: AppTextStyles.bodyMedium),
            const SizedBox(height: 4),
            Text(
              '${address['district']}, ${address['city']}, ${address['province']} ${address['postalCode']}',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600]),
            ),

            // Notes if available
            if (address['notes'] != null &&
                address['notes'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        address['notes'],
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text('Alamat Saya', style: AppTextStyles.heading2),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAddresses,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _addresses.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_off_outlined,
                      size: 80,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada alamat tersimpan',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tambahkan alamat pengiriman Anda',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.1),
                          AppColors.primary.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Alamat utama akan dipilih secara otomatis saat checkout',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Address list
                  ..._addresses.map((address) => _buildAddressCard(address)),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddressForm(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Alamat'),
      ),
    );
  }
}
