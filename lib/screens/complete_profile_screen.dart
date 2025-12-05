import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rempah_nusantara/config/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();

  File? _profileImage;
  String? _selectedGender;
  String? _selectedProvince;
  bool _isLoading = false;
  int _currentStep = 0;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _provinces = [
    'DKI Jakarta',
    'Jawa Barat',
    'Jawa Tengah',
    'Jawa Timur',
    'Banten',
    'DI Yogyakarta',
    'Bali',
    'Sumatera Utara',
    'Sumatera Barat',
    'Sumatera Selatan',
  ];

  // Preferences
  final List<Map<String, dynamic>> _dietaryPreferences = [
    {'name': 'Vegetarian', 'icon': Icons.eco, 'selected': false},
    {'name': 'Vegan', 'icon': Icons.spa, 'selected': false},
    {'name': 'Halal', 'icon': Icons.mosque, 'selected': false},
    {'name': 'No Pork', 'icon': Icons.no_food, 'selected': false},
    {'name': 'Gluten Free', 'icon': Icons.grain, 'selected': false},
    {'name': 'Dairy Free', 'icon': Icons.local_drink, 'selected': false},
  ];

  final List<Map<String, dynamic>> _cuisinePreferences = [
    {'name': 'Indonesian', 'selected': false},
    {'name': 'Chinese', 'selected': false},
    {'name': 'Japanese', 'selected': false},
    {'name': 'Indian', 'selected': false},
    {'name': 'Western', 'selected': false},
    {'name': 'Middle Eastern', 'selected': false},
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLarge),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 512,
                  maxHeight: 512,
                  imageQuality: 85,
                );
                if (image != null && mounted) {
                  setState(() {
                    _profileImage = File(image.path);
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppColors.primary,
              ),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 512,
                  maxHeight: 512,
                  imageQuality: 85,
                );
                if (image != null && mounted) {
                  setState(() {
                    _profileImage = File(image.path);
                  });
                }
              },
            ),
            if (_profileImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text('Remove Photo'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _profileImage = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // TODO: Upload profile image to server
    // TODO: Save profile data to API

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      // Navigate to home
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
          color: AppColors.textPrimary,
        ),
        title: Text(
          'Complete Your Profile',
          style: AppTextStyles.heading3.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.paddingLarge),
              child: Form(
                key: _formKey,
                child: _currentStep == 0
                    ? _buildBasicInfoStep()
                    : _currentStep == 1
                    ? _buildAddressStep()
                    : _buildPreferencesStep(),
              ),
            ),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      color: AppColors.surface,
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < 2)
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.primary
                          : isActive
                          ? AppColors.primary.withOpacity(0.2)
                          : AppColors.border,
                      shape: BoxShape.circle,
                    ),
                    child: isCompleted
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: AppColors.surface,
                          )
                        : Center(
                            child: Text(
                              '${index + 1}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isActive
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: AppSizes.spacingLarge),
        Text(
          'Tell us about yourself',
          style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.spacingSmall),
        Text(
          'Add your photo and basic information',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.spacingLarge * 2),
        Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 3),
                color: AppColors.surface,
              ),
              child: _profileImage != null
                  ? ClipOval(
                      child: Image.file(_profileImage!, fit: BoxFit.cover),
                    )
                  : const Icon(
                      Icons.person,
                      size: 60,
                      color: AppColors.textSecondary,
                    ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: InkWell(
                onTap: _pickImage,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: AppColors.surface,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spacingLarge * 2),
        TextFormField(
          controller: _fullNameController,
          decoration: InputDecoration(
            labelText: 'Full Name',
            hintText: 'Enter your full name',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your full name';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSizes.spacingMedium),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            hintText: '+62 812 3456 7890',
            prefixIcon: const Icon(Icons.phone_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSizes.spacingMedium),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          decoration: InputDecoration(
            labelText: 'Gender',
            prefixIcon: const Icon(Icons.wc_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            ),
          ),
          items: _genderOptions.map((gender) {
            return DropdownMenuItem(value: gender, child: Text(gender));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedGender = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select your gender';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAddressStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSizes.spacingLarge),
        Text(
          'Where do you live?',
          style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSizes.spacingSmall),
        Text(
          'This helps us provide better service',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSizes.spacingLarge * 2),
        TextFormField(
          controller: _addressController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Street Address',
            hintText: 'Enter your street address',
            prefixIcon: const Icon(Icons.home_outlined),
            alignLabelWithHint: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your address';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSizes.spacingMedium),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'City',
                  hintText: 'City',
                  prefixIcon: const Icon(Icons.location_city_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: AppSizes.spacingMedium),
            Expanded(
              child: TextFormField(
                controller: _postalCodeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Postal Code',
                  hintText: '12345',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spacingMedium),
        DropdownButtonFormField<String>(
          value: _selectedProvince,
          decoration: InputDecoration(
            labelText: 'Province',
            prefixIcon: const Icon(Icons.map_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            ),
          ),
          items: _provinces.map((province) {
            return DropdownMenuItem(value: province, child: Text(province));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedProvince = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select your province';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPreferencesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSizes.spacingLarge),
        Text(
          'Set your preferences',
          style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSizes.spacingSmall),
        Text(
          'Help us personalize your experience',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSizes.spacingLarge * 2),
        Text(
          'Dietary Preferences',
          style: AppTextStyles.heading4.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSizes.spacingMedium),
        Wrap(
          spacing: AppSizes.spacingSmall,
          runSpacing: AppSizes.spacingSmall,
          children: _dietaryPreferences.map((pref) {
            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(pref['icon'] as IconData, size: 16),
                  const SizedBox(width: 4),
                  Text(pref['name']),
                ],
              ),
              selected: pref['selected'],
              onSelected: (selected) {
                setState(() {
                  pref['selected'] = selected;
                });
              },
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
            );
          }).toList(),
        ),
        const SizedBox(height: AppSizes.spacingLarge),
        Text(
          'Favorite Cuisines',
          style: AppTextStyles.heading4.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSizes.spacingMedium),
        Wrap(
          spacing: AppSizes.spacingSmall,
          runSpacing: AppSizes.spacingSmall,
          children: _cuisinePreferences.map((pref) {
            return ChoiceChip(
              label: Text(pref['name']),
              selected: pref['selected'],
              onSelected: (selected) {
                setState(() {
                  pref['selected'] = selected;
                });
              },
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: pref['selected']
                    ? AppColors.surface
                    : AppColors.textPrimary,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _currentStep--;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSizes.paddingMedium,
                    ),
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSizes.radiusMedium,
                      ),
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: AppSizes.spacingMedium),
            Expanded(
              flex: _currentStep > 0 ? 1 : 1,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        if (_currentStep < 2) {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              _currentStep++;
                            });
                          }
                        } else {
                          _saveProfile();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSizes.paddingMedium,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.surface,
                          ),
                        ),
                      )
                    : Text(
                        _currentStep < 2 ? 'Continue' : 'Complete',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.surface,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
