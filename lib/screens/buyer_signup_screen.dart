import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:myapp/services/api_service.dart';

class BuyerSignupScreen extends StatefulWidget {
  const BuyerSignupScreen({super.key});

  @override
  State<BuyerSignupScreen> createState() => _BuyerSignupScreenState();
}

class _BuyerSignupScreenState extends State<BuyerSignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _dobController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signup() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.signup(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'full_name': _nameController.text.trim(),
          'mobile_number': _mobileController.text.trim(),
          'date_of_birth': _dobController.text.trim(),
        },
      );

      if (result['success'] == true) {
        if (mounted) {
          AwesomeDialog(
            context: context,
            dialogType: DialogType.success,
            animType: AnimType.bottomSlide,
            title: 'Pendaftaran Berhasil!',
            desc:
                'Akun Anda telah dibuat. Anda akan diarahkan ke halaman utama.',
            btnOkOnPress: () {
              context.go('/');
            },
          ).show();
        }
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan yang tidak terduga: $e')),
        );
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
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F4),
      appBar: AppBar(
        title: const Text(
          'Sign Up Buyer',
          style: TextStyle(
            color: Color(0xFF4A4A4A),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFFBF9F4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4A4A4A)),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                _buildTextField(
                  label: 'Full Name',
                  hint: 'John Doe',
                  controller: _nameController,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  label: 'Email',
                  hint: 'example@example.com',
                  controller: _emailController,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  label: 'Mobile Number',
                  hint: '+123 456 789',
                  controller: _mobileController,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  label: 'Date Of Birth',
                  hint: 'DD / MM / YYYY',
                  controller: _dobController,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  label: 'Password',
                  hint: '••••••••',
                  isPassword: true,
                  controller: _passwordController,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  label: 'Confirm Password',
                  hint: '••••••••',
                  isPassword: true,
                  controller: _confirmPasswordController,
                ),
                const SizedBox(height: 30),
                const Text(
                  'By continuing, you agree to\nTerms of Use and Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _signup,
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
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account?",
                      style: TextStyle(color: Colors.black54),
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text(
                        'Log In',
                        style: TextStyle(
                          color: Color(0xFF4D5D42),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    bool isPassword = false,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF4A4A4A),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFF4D5D42),
            hintStyle: const TextStyle(color: Colors.white54),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25.0),
              borderSide: BorderSide.none,
            ),
            suffixIcon: isPassword
                ? const Icon(Icons.visibility_off, color: Colors.white54)
                : null,
          ),
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }
}
