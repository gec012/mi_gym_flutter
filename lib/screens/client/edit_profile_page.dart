import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mi_gym_flutter/services/supabase_service.dart';
import 'package:intl/intl.dart';
import 'package:mi_gym_flutter/theme/app_colors.dart';
import 'package:mi_gym_flutter/utils/validators.dart';
import 'package:mi_gym_flutter/widgets/shared/primary_button.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic>? profile;
  final VoidCallback onProfileUpdated;

  const EditProfilePage({
    super.key,
    required this.profile,
    required this.onProfileUpdated,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _birthDateController;
  
  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _isUploading = false;
  String? _currentAvatarUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile?['full_name'] ?? '');
    _phoneController = TextEditingController(text: widget.profile?['phone'] ?? '');
    _currentAvatarUrl = widget.profile?['avatar_url'];
    
    if (widget.profile?['birth_date'] != null) {
      _selectedDate = DateTime.parse(widget.profile?['birth_date']);
      _birthDateController = TextEditingController(
        text: DateFormat('MMMM d, y').format(_selectedDate!),
      );
    } else {
      _birthDateController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final bytes = await image.readAsBytes();
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final publicUrl = await SupabaseService.uploadProfileImage(
        imageBytes: bytes,
        fileName: fileName,
      );

      setState(() {
        _currentAvatarUrl = publicUrl;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo uploaded! Save changes to apply.'))
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(1995),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.backgroundDark,
              surface: AppColors.surfaceDark,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _birthDateController.text = DateFormat('MMMM d, y').format(picked);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updates = {
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'birth_date': _selectedDate?.toIso8601String().substring(0, 10),
        'avatar_url': _currentAvatarUrl,
      };

      await SupabaseService.updateUserProfile(updates);
      
      if (!mounted) return;
      
      widget.onProfileUpdated();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!'))
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = AppColors.primary;
    const Color backgroundDark = AppColors.backgroundDark;
    const Color slate800 = AppColors.slate800;

    return Scaffold(
      backgroundColor: backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Profile Picture
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.2),
                              width: 4,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: slate800,
                            backgroundImage: _currentAvatarUrl != null
                                ? NetworkImage(_currentAvatarUrl!)
                                : const NetworkImage('https://images.unsplash.com/photo-1548690312-e3b507d8c110?q=80&w=300'),
                          ),
                        ),
                        GestureDetector(
                          onTap: _isUploading ? null : _pickAndUploadImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: backgroundDark, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: backgroundDark,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Change Profile Photo',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Fields
              _buildFieldLabel('Full Name'),
              _buildTextField(
                controller: _nameController,
                hint: 'Your name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 24),

              _buildFieldLabel('Email Address'),
              _buildTextField(
                controller: TextEditingController(text: SupabaseService.currentUser?.email ?? ''),
                hint: 'Email',
                icon: Icons.email_outlined,
                enabled: false,
              ),
              const SizedBox(height: 24),

              _buildFieldLabel('Phone Number'),
              _buildTextField(
                controller: _phoneController,
                hint: '+1 (555) 000-0000',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),

              _buildFieldLabel('Date of Birth'),
              GestureDetector(
                onTap: _selectDate,
                child: AbsorbPointer(
                  child: _buildTextField(
                    controller: _birthDateController,
                    hint: 'Select your birth date',
                    icon: Icons.calendar_month_outlined,
                    isDate: true,
                  ),
                ),
              ),

              const SizedBox(height: 60),

              // Save Button
              PrimaryButton(
                text: 'Save Changes',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _saveProfile,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool enabled = true,
    bool isDate = false,
    TextInputType? keyboardType,
  }) {
    const Color primaryColor = AppColors.primary;
    
    return Container(
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        style: TextStyle(
          color: enabled ? Colors.white : Colors.white60,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
          prefixIcon: Icon(icon, color: primaryColor, size: 20),
          suffixIcon: isDate 
            ? const Icon(Icons.arrow_drop_down, color: primaryColor) 
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        validator: enabled
            ? (value) => Validators.required(value, 'Please enter this field')
            : null,
      ),
    );
  }
}
