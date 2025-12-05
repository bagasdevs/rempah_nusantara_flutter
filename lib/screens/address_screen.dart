import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/config/app_theme.dart';
import 'package:myapp/services/api_service.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _addresses = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final addresses = await ApiService.getAddresses();
      setState(() {
        _addresses = addresses;
        _isLoading = false;
      });
      print('✅ Loaded ${addresses.length} addresses');
    } catch (e) {
      print('❌ Error loading addresses: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat alamat: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _refreshAddresses() async {
    await _loadAddresses();
  }

  Future<void> _setDefaultAddress(int id) async {
    try {
      await ApiService.updateAddress(addressId: id, isDefault: true);

      // Reload addresses to get updated data
      await _loadAddresses();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alamat utama berhasil diubah'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('❌ Error setting default address: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah alamat utama: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _editAddress(Map<String, dynamic> address) {
    _showAddressForm(address: address);
  }

  Future<void> _deleteAddress(int id) async {
    final address = _addresses.firstWhere((a) => a['id'] == id);

    if (address['is_default'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat menghapus alamat utama'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Alamat'),
        content: const Text('Apakah Anda yakin ingin menghapus alamat ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Hapus', style: TextStyle(color: Colors.red[700])),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.deleteAddress(id);
        await _loadAddresses();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Alamat berhasil dihapus'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        print('❌ Error deleting address: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus alamat: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _showAddressForm({Map<String, dynamic>? address}) {
    final isEdit = address != null;
    final labelController = TextEditingController(
      text: address?['label'] ?? '',
    );
    final nameController = TextEditingController(
      text: address?['recipient_name'] ?? '',
    );
    final phoneController = TextEditingController(
      text: address?['phone'] ?? '',
    );
    final addressController = TextEditingController(
      text: address?['address'] ?? '',
    );
    final cityController = TextEditingController(text: address?['city'] ?? '');
    final provinceController = TextEditingController(
      text: address?['province'] ?? '',
    );
    final postalCodeController = TextEditingController(
      text: address?['postal_code'] ?? '',
    );
    final notesController = TextEditingController(
      text: address?['notes'] ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Edit Alamat' : 'Tambah Alamat Baru',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: labelController,
                decoration: const InputDecoration(
                  labelText: 'Label',
                  hintText: 'Contoh: Rumah, Kantor',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Penerima',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nomor Telepon',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Alamat Lengkap',
                  hintText: 'Nama jalan, nomor rumah, RT/RW',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cityController,
                decoration: const InputDecoration(
                  labelText: 'Kota/Kabupaten',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: provinceController,
                decoration: const InputDecoration(
                  labelText: 'Provinsi',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: postalCodeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Kode Pos',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Catatan (Opsional)',
                  hintText: 'Patokan atau instruksi pengiriman',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    // Validate
                    if (labelController.text.isEmpty ||
                        nameController.text.isEmpty ||
                        phoneController.text.isEmpty ||
                        addressController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Harap isi semua field yang wajib'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    try {
                      if (isEdit) {
                        // Update address
                        await ApiService.updateAddress(
                          addressId: address['id'],
                          label: labelController.text,
                          recipientName: nameController.text,
                          phone: phoneController.text,
                          address: addressController.text,
                          city: cityController.text.isNotEmpty
                              ? cityController.text
                              : null,
                          province: provinceController.text.isNotEmpty
                              ? provinceController.text
                              : null,
                          postalCode: postalCodeController.text.isNotEmpty
                              ? postalCodeController.text
                              : null,
                          notes: notesController.text.isNotEmpty
                              ? notesController.text
                              : null,
                        );
                      } else {
                        // Create new address
                        await ApiService.createAddress(
                          label: labelController.text,
                          recipientName: nameController.text,
                          phone: phoneController.text,
                          address: addressController.text,
                          city: cityController.text.isNotEmpty
                              ? cityController.text
                              : null,
                          province: provinceController.text.isNotEmpty
                              ? provinceController.text
                              : null,
                          postalCode: postalCodeController.text.isNotEmpty
                              ? postalCodeController.text
                              : null,
                          notes: notesController.text.isNotEmpty
                              ? notesController.text
                              : null,
                        );
                      }

                      // Reload addresses
                      await _loadAddresses();

                      if (context.mounted) {
                        Navigator.of(context).pop();
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
                      }
                    } catch (e) {
                      print('❌ Error saving address: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Gagal menyimpan alamat: $e'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Alamat'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alamat Pengiriman'), elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Gagal memuat alamat',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadAddresses,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          : _addresses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada alamat',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tambahkan alamat pengiriman Anda',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddressForm(),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Alamat'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshAddresses,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _addresses.length,
                itemBuilder: (context, index) {
                  final address = _addresses[index];
                  final isDefault = address['is_default'] == true;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isDefault
                          ? BorderSide(color: AppColors.primary, width: 2)
                          : BorderSide.none,
                    ),
                    child: InkWell(
                      onTap: () {
                        // Return selected address
                        context.pop(address);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDefault
                                        ? AppColors.primary
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.label,
                                        size: 16,
                                        color: isDefault
                                            ? Colors.white
                                            : Colors.grey[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        address['label'] ?? '',
                                        style: TextStyle(
                                          color: isDefault
                                              ? Colors.white
                                              : Colors.grey[700],
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isDefault) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Utama',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                PopupMenuButton(
                                  icon: const Icon(Icons.more_vert),
                                  itemBuilder: (context) => [
                                    if (!isDefault)
                                      PopupMenuItem(
                                        onTap: () =>
                                            _setDefaultAddress(address['id']),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.check_circle, size: 20),
                                            SizedBox(width: 8),
                                            Text('Jadikan Utama'),
                                          ],
                                        ),
                                      ),
                                    PopupMenuItem(
                                      onTap: () => _editAddress(address),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.edit, size: 20),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    if (!isDefault)
                                      PopupMenuItem(
                                        onTap: () =>
                                            _deleteAddress(address['id']),
                                        child: const Row(
                                          children: [
                                            Icon(
                                              Icons.delete,
                                              size: 20,
                                              color: Colors.red,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Hapus',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              address['recipient_name'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              address['phone'] ?? '',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              address['address'] ?? '',
                              style: const TextStyle(fontSize: 14),
                            ),
                            if (address['city'] != null ||
                                address['province'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                [
                                      address['city'],
                                      address['province'],
                                      address['postal_code'],
                                    ]
                                    .where(
                                      (e) =>
                                          e != null && e.toString().isNotEmpty,
                                    )
                                    .join(', '),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                            if (address['notes'] != null &&
                                address['notes'].toString().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        address['notes'] ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
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
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: !_isLoading && _addresses.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showAddressForm(),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Alamat'),
            )
          : null,
    );
  }
}
