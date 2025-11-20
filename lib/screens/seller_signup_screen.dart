import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SellerSignupScreen extends StatefulWidget {
  const SellerSignupScreen({super.key});

  @override
  State<SellerSignupScreen> createState() => _SellerSignupScreenState();
}

class _SellerSignupScreenState extends State<SellerSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  Future<void> _updateProfileToBeSeller() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      // Seharusnya tidak terjadi jika alurnya benar, tapi sebagai pengaman
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda harus login terlebih dahulu.')),
      );
      context.go('/login');
      return;
    }

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({
            'role': 'seller',
            'business_name': _businessNameController.text.trim(),
            'full_address': _addressController.text.trim(),
          })
          .eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selamat! Anda sekarang adalah penjual.'),
          ),
        );
        // Arahkan ke home, saat kembali ke settings, role akan terupdate
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F4),
      appBar: AppBar(
        title: const Text(
          'Daftar Sebagai Penjual',
          style: TextStyle(
            color: Color(0xFF4A4A4A),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFFBF9F4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4A4A4A)),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _businessNameController,
                decoration: const InputDecoration(labelText: 'Nama Usaha/Toko'),
                validator: (value) =>
                    value!.isEmpty ? 'Nama usaha tidak boleh kosong' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Alamat Lengkap'),
                maxLines: 3,
                validator: (value) =>
                    value!.isEmpty ? 'Alamat tidak boleh kosong' : null,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateProfileToBeSeller,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4D5D42),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Kirim Pendaftaran',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
