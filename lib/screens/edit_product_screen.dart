import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProductScreen extends StatefulWidget {
  final int? productId;
  const EditProductScreen({super.key, this.productId});

  bool get isEditMode => productId != null;

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _categoryController = TextEditingController();

  bool _isLoading = false;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) {
      _fetchProductDetails();
    }
  }

  Future<void> _fetchProductDetails() async {
    setState(() => _isLoading = true);
    try {
      final product = await _supabase
          .from('products')
          .select()
          .eq('id', widget.productId!)
          .single();

      _nameController.text = product['name'] ?? '';
      _descriptionController.text = product['description'] ?? '';
      _priceController.text = product['price']?.toString() ?? '';
      _stockController.text = product['stock']?.toString() ?? '';
      _imageUrlController.text = product['image_url'] ?? '';
      _categoryController.text = product['category'] ?? '';
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat data produk: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Ambil nama penjual dari profil
      final profile = await _supabase
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .single();
      final sellerName = profile['full_name'];

      final productData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'stock': int.parse(_stockController.text.trim()),
        'category': _categoryController.text.trim(),
        'image_url': _imageUrlController.text.trim(),
        'seller_id': user.id,
        'seller_name': sellerName,
      };

      if (widget.isEditMode) {
        // Update mode
        await _supabase
            .from('products')
            .update(productData)
            .eq('id', widget.productId!);
      } else {
        // Create mode
        await _supabase.from('products').insert(productData);
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Produk berhasil disimpan!')));
        context.pop(true); // Kembali dan kirim sinyal untuk refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan produk: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode ? 'Edit Produk' : 'Tambah Produk'),
        backgroundColor: const Color(0xFFFBF9F4),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextFormField(_nameController, 'Nama Produk'),
                    _buildTextFormField(
                      _descriptionController,
                      'Deskripsi',
                      maxLines: 3,
                    ),
                    _buildTextFormField(
                      _priceController,
                      'Harga',
                      keyboardType: TextInputType.number,
                    ),
                    _buildTextFormField(
                      _stockController,
                      'Stok',
                      keyboardType: TextInputType.number,
                    ),
                    _buildTextFormField(
                      _categoryController,
                      'Kategori (misal: Rimpang)',
                    ),
                    _buildTextFormField(
                      _imageUrlController,
                      'URL Gambar Produk',
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4D5D42),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Simpan Produk',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextFormField(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Colors.grey.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$label tidak boleh kosong';
          }
          if (keyboardType == TextInputType.number) {
            if (double.tryParse(value) == null) {
              return 'Masukkan angka yang valid';
            }
          }
          return null;
        },
      ),
    );
  }
}
