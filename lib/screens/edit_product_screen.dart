import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

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

  bool _isLoading = false;
  final _supabase = Supabase.instance.client;

  // State untuk kategori dan gambar
  late Future<List<Map<String, dynamic>>> _categoriesFuture;
  int? _selectedCategoryId;
  XFile? _selectedImageFile;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _fetchCategories();
    if (widget.isEditMode) {
      _fetchProductDetails();
    }
  }

  Future<List<Map<String, dynamic>>> _fetchCategories() async {
    final response = await _supabase.from('categories').select('id, name');
    return response as List<Map<String, dynamic>>;
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
      _existingImageUrl = product['image_url'];
      _selectedCategoryId = product['category_id'];
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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImageFile = image;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    String? imageUrl;

    // 1. Proses upload gambar jika ada gambar baru yang dipilih
    if (_selectedImageFile != null) {
      try {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}.${_selectedImageFile!.path.split('.').last}';
        final filePath = '${user.id}/$fileName';

        if (kIsWeb) {
          // Logika untuk Web: Gunakan uploadBinary.
          final imageBytes = await _selectedImageFile!.readAsBytes();
          await _supabase.storage
              .from('product_images')
              .uploadBinary(filePath, imageBytes);
        } else {
          // Logika untuk Mobile: Gunakan upload dengan File.
          final file = File(_selectedImageFile!.path);
          await _supabase.storage.from('product_images').upload(filePath, file);
        }
        imageUrl = _supabase
            .storage // Ambil URL setelah upload berhasil
            .from('product_images')
            .getPublicUrl(filePath);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengupload gambar: $e')),
          );
          setState(() => _isLoading = false);
          return;
        }
      }
    } else {
      // Jika tidak ada gambar baru, gunakan URL gambar yang sudah ada (untuk mode edit)
      imageUrl = _existingImageUrl;
    }

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
        'category_id': _selectedCategoryId,
        'seller_id': user.id,
        'seller_name': sellerName,
        'image_url':
            imageUrl, // Gunakan URL dari gambar yang diupload atau yang sudah ada
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
                    // --- Input Gambar ---
                    _buildImagePicker(),
                    const SizedBox(height: 16),

                    // --- Input Form Lainnya ---
                    _buildTextFormField(_nameController, 'Nama Produk'),
                    _buildTextFormField(
                      _descriptionController,
                      'Deskripsi',
                      maxLines: 3,
                    ),
                    // --- Dropdown Kategori ---
                    _buildCategoryDropdown(),
                    const SizedBox(height: 8),
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

  Widget _buildImagePicker() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _selectedImageFile != null
                  ? kIsWeb // Cek apakah platformnya web
                        ? Image.network(
                            _selectedImageFile!.path,
                            fit: BoxFit.cover,
                          ) // Jika web
                        : Image.file(
                            // Jika bukan web
                            File(_selectedImageFile!.path),
                            fit: BoxFit.cover,
                          )
                  : (_existingImageUrl != null
                        ? Image.network(_existingImageUrl!, fit: BoxFit.cover)
                        : const Center(
                            child: Icon(
                              Icons.image,
                              color: Colors.grey,
                              size: 50,
                            ),
                          )),
            ),
          ),
          TextButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.upload_file),
            label: const Text('Pilih Gambar Produk'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final categories = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: DropdownButtonFormField<int>(
            value: _selectedCategoryId,
            decoration: InputDecoration(
              labelText: 'Kategori',
              labelStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.grey.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: categories.map((category) {
              return DropdownMenuItem<int>(
                value: category['id'],
                child: Text(category['name']),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategoryId = value;
              });
            },
            validator: (value) => value == null ? 'Pilih kategori' : null,
          ),
        );
      },
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
