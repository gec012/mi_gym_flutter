import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mi_gym_flutter/providers/user_session.dart';
import 'package:mi_gym_flutter/screens/auth/login_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mi_gym_flutter/services/supabase_service.dart';
import 'package:mi_gym_flutter/models/class_model.dart';
import 'package:mi_gym_flutter/models/category_model.dart';
import 'package:mi_gym_flutter/models/instructor_model.dart';
import 'package:mi_gym_flutter/theme/app_colors.dart';
import 'package:mi_gym_flutter/utils/validators.dart';
import 'package:mi_gym_flutter/widgets/shared/primary_button.dart';

/// Page for creating a new class or editing an existing one.
/// Pass [classData] to edit; leave null to create.
class CreateEditClassPage extends StatefulWidget {
  final ClassModel? classData;

  const CreateEditClassPage({super.key, this.classData});

  bool get isEditing => classData != null;

  @override
  State<CreateEditClassPage> createState() => _CreateEditClassPageState();
}

class _CreateEditClassPageState extends State<CreateEditClassPage> {
  // --- Theme colors ---
  final Color primaryColor = AppColors.primary;
  final Color backgroundDark = AppColors.backgroundDark;
  final Color surfaceColor = AppColors.surfaceDark;
  final Color inputColor = const Color(0xFF1E1E1E);
  final Color slate500 = AppColors.slate500;
  final Color slate400 = AppColors.slate400;
  final Color slate300 = AppColors.slate300;

  // --- Controllers ---
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _capacityController;
  late TextEditingController _durationController;
  late TextEditingController _priceController;
  late TextEditingController _locationController;
  late TextEditingController _imageUrlController;

  // --- State ---
  String _selectedIntensity = 'Medium';
  String? _selectedCategoryId;
  String? _selectedInstructorId;
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  List<CategoryModel> _categories = [];
  List<InstructorModel> _instructors = [];
  bool _isLoading = false;
  bool _isDataLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();

    // GUARD: Protección de ruta para asegurar que solo Admins editen o creen clases
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = Provider.of<UserSession>(context, listen: false);
      if (!session.isAdmin) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
      }
    });

    final data = widget.classData;
    _nameController = TextEditingController(text: data?.name ?? '');
    _descriptionController = TextEditingController(
      text: data?.description ?? '',
    );
    _capacityController = TextEditingController(
      text: data != null ? data.capacity.toString() : '20',
    );
    _durationController = TextEditingController(
      text: data != null ? data.durationMinutes.toString() : '',
    );
    _priceController = TextEditingController(
      text: data != null ? data.basePrice.toString() : '',
    );
    _locationController = TextEditingController();
    _imageUrlController = TextEditingController(text: data?.imageUrl ?? '');

    if (data != null) {
      _selectedIntensity = data.intensity;
      _selectedCategoryId = data.categoryId;
    }

    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    try {
      final results = await Future.wait<dynamic>([
        SupabaseService.getCategories(),
        SupabaseService.getInstructors(),
      ]);
      setState(() {
        _categories = results[0] as List<CategoryModel>;
        _instructors = results[1] as List<InstructorModel>;
        _isDataLoading = false;
      });
    } catch (e) {
      setState(() => _isDataLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => _datePickerTheme(child),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart
        ? (_startTime ?? const TimeOfDay(hour: 8, minute: 0))
        : (_endTime ?? const TimeOfDay(hour: 9, minute: 0));
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => _datePickerTheme(child),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Widget _datePickerTheme(Widget? child) {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: primaryColor,
          onPrimary: Colors.white,
          surface: surfaceColor,
        ),
      ),
      child: child!,
    );
  }

  Future<void> _saveClass() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final duration = int.tryParse(_durationController.text.trim()) ?? 60;
      final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final imageUrl = _imageUrlController.text.trim().isNotEmpty
          ? _imageUrlController.text.trim()
          : null;

      final capacity = int.tryParse(_capacityController.text.trim()) ?? 20;

      if (widget.isEditing) {
        // --- UPDATE class ---
        await SupabaseService.updateClass(
          classId: widget.classData!.id,
          name: name,
          description: description.isNotEmpty ? description : null,
          imageUrl: imageUrl,
          categoryId: _selectedCategoryId,
          intensity: _selectedIntensity,
          durationMinutes: duration,
          capacity: capacity,
          basePrice: price,
        );
      } else {
        // --- CREATE class ---
        final newClass = await SupabaseService.createClass(
          name: name,
          description: description.isNotEmpty ? description : null,
          imageUrl: imageUrl,
          categoryId: _selectedCategoryId,
          intensity: _selectedIntensity,
          durationMinutes: duration,
          capacity: capacity,
          basePrice: price,
        );

        // If schedule data provided, create a schedule too
        if (_selectedDate != null &&
            _startTime != null &&
            _endTime != null &&
            _selectedInstructorId != null) {
          final capacity = int.tryParse(_capacityController.text.trim()) ?? 25;
          final location = _locationController.text.trim();

          final startDt = DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            _startTime!.hour,
            _startTime!.minute,
          );
          final endDt = DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            _endTime!.hour,
            _endTime!.minute,
          );

          await SupabaseService.createSchedule(
            classId: newClass.id,
            instructorId: _selectedInstructorId!,
            startTime: startDt,
            endTime: endDt,
            capacity: capacity,
            locationName: location.isNotEmpty ? location : null,
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing
                  ? 'Class updated successfully!'
                  : 'Class created successfully!',
            ),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
        Navigator.of(context).pop(true); // signal success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteClass() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Delete Class',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to delete this class? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: slate400)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await SupabaseService.deleteClass(widget.classData!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Class deleted'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===== BUILD =====

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundDark,
      body: _isDataLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildCoverPhoto(),
                            const SizedBox(height: 8),
                            _buildTextField(
                              label: 'CLASS NAME',
                              controller: _nameController,
                              hint: 'HIIT Morning Blast',
                              icon: Icons.open_in_full,
                              validator: (v) => Validators.required(v, 'Name is required'),
                            ),
                            _buildInstructorPicker(),
                            _buildCategoryPicker(),
                            _buildIntensityPicker(),
                            _buildTextField(
                              label: 'DURATION (MINUTES)',
                              controller: _durationController,
                              hint: 'e.g. 45',
                              icon: Icons.timer_outlined,
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Duration is required';
                                }
                                if (int.tryParse(v.trim()) == null) {
                                  return 'Enter a valid number';
                                }
                                return null;
                              },
                            ),
                            _buildTextField(
                              label: 'BASE PRICE',
                              controller: _priceController,
                              hint: '0.00',
                              icon: Icons.attach_money,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                            ),
                            _buildTextField(
                              label: 'IMAGE URL',
                              controller: _imageUrlController,
                              hint: 'https://...',
                              icon: Icons.image_outlined,
                            ),
                            // --- Schedule section (only for create) ---
                            if (!widget.isEditing) ...[
                              _buildSectionHeader('SCHEDULE (OPTIONAL)'),
                              _buildDatePicker(),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTimePicker(
                                      label: 'START TIME',
                                      isStart: true,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildTimePicker(
                                      label: 'END TIME',
                                      isStart: false,
                                    ),
                                  ),
                                ],
                              ),
                              _buildTextField(
                                label: 'MAX CAPACITY',
                                controller: _capacityController,
                                hint: 'e.g. 20',
                                icon: Icons.groups_outlined,
                                keyboardType: TextInputType.number,
                              ),
                              _buildTextField(
                                label: 'LOCATION',
                                controller: _locationController,
                                hint: 'Studio A',
                                icon: Icons.location_on_outlined,
                              ),
                            ],
                            _buildDescriptionField(),
                            const SizedBox(height: 16),
                            _buildActionButtons(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // --- App Bar ---
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundDark,
        border: Border(
          bottom: BorderSide(color: primaryColor.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: slate400,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            widget.isEditing ? 'Edit Class' : 'Create Class',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 48), // spacer
        ],
      ),
    );
  }

  // --- Cover Photo ---
  Widget _buildCoverPhoto() {
    final imageUrl = _imageUrlController.text.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: GestureDetector(
        onTap: _isUploading ? null : _showImagePickerOptions,
        child: Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(24),
            image: imageUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.4),
                      BlendMode.darken,
                    ),
                  )
                : null,
          ),
          child: _isUploading
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Uploading...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      imageUrl.isNotEmpty ? Icons.edit : Icons.photo_camera,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      imageUrl.isNotEmpty
                          ? 'tap to change cover'
                          : 'tap to upload cover',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Upload Cover Photo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.photo_library, color: primaryColor),
                ),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Select an existing photo',
                  style: TextStyle(color: slate500, fontSize: 12),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.camera_alt, color: primaryColor),
                ),
                title: const Text(
                  'Take a Photo',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Use your camera',
                  style: TextStyle(color: slate500, fontSize: 12),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (picked == null) return;

      setState(() => _isUploading = true);

      final bytes = await picked.readAsBytes();
      final ext = picked.name.split('.').last;
      final fileName = 'cover_${DateTime.now().millisecondsSinceEpoch}.$ext';

      final publicUrl = await SupabaseService.uploadClassImage(
        imageBytes: bytes,
        fileName: fileName,
      );

      setState(() {
        _imageUrlController.text = publicUrl;
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded successfully!'),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- Generic Text Field ---
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: slate400,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: inputColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              validator: validator,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: slate500),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                suffixIcon: icon != null
                    ? Icon(icon, color: slate500, size: 20)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Instructor Picker ---
  Widget _buildInstructorPicker() {
    final selected = _instructors.cast<InstructorModel?>().firstWhere(
      (i) => i?.id == _selectedInstructorId,
      orElse: () => null,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INSTRUCTOR',
            style: TextStyle(
              color: slate400,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showInstructorBottomSheet(),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: inputColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  if (selected != null) ...[
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: slate500,
                      backgroundImage: selected.avatarUrl != null
                          ? NetworkImage(selected.avatarUrl!)
                          : null,
                      child: selected.avatarUrl == null
                          ? const Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        selected.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ] else
                    Expanded(
                      child: Text(
                        'Select instructor',
                        style: TextStyle(color: slate500),
                      ),
                    ),
                  Icon(Icons.expand_more, color: slate500),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInstructorBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Select Instructor',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ..._instructors.map(
            (i) => ListTile(
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: slate500,
                backgroundImage: i.avatarUrl != null
                    ? NetworkImage(i.avatarUrl!)
                    : null,
                child: i.avatarUrl == null
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
              title: Text(i.name, style: const TextStyle(color: Colors.white)),
              trailing: _selectedInstructorId == i.id
                  ? Icon(Icons.check_circle, color: primaryColor)
                  : null,
              onTap: () {
                setState(() => _selectedInstructorId = i.id);
                Navigator.of(ctx).pop();
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Category Picker ---
  Widget _buildCategoryPicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CATEGORY',
            style: TextStyle(
              color: slate400,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: inputColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategoryId,
                isExpanded: true,
                hint: Text(
                  'Select category',
                  style: TextStyle(color: slate500),
                ),
                dropdownColor: surfaceColor,
                icon: Icon(Icons.expand_more, color: slate500),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                items: _categories.map((c) {
                  return DropdownMenuItem<String>(
                    value: c.id,
                    child: Text(c.name),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategoryId = val),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Intensity Picker ---
  Widget _buildIntensityPicker() {
    const intensities = ['Low', 'Medium', 'High'];
    final intensityColors = {
      'Low': const Color(0xFF22C55E),
      'Medium': const Color(0xFFF59E0B),
      'High': const Color(0xFF7C3AED),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INTENSITY',
            style: TextStyle(
              color: slate400,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: intensities.map((level) {
              final isSelected = _selectedIntensity == level;
              final color = intensityColors[level]!;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedIntensity = level),
                  child: Container(
                    height: 44,
                    margin: EdgeInsets.only(right: level != 'High' ? 8 : 0),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.15)
                          : inputColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? color
                            : Colors.white.withValues(alpha: 0.05),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        level,
                        style: TextStyle(
                          color: isSelected ? color : slate500,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- Section Header ---
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Row(
        children: [
          Container(width: 3, height: 16, color: primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: slate400,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // --- Date Picker ---
  Widget _buildDatePicker() {
    final dateText = _selectedDate != null
        ? DateFormat('MM/dd/yyyy').format(_selectedDate!)
        : 'mm/dd/yyyy';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DATE',
            style: TextStyle(
              color: slate400,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: inputColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateText,
                    style: TextStyle(
                      color: _selectedDate != null ? Colors.white : slate500,
                    ),
                  ),
                  Icon(Icons.calendar_today, color: slate500, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Time Picker ---
  Widget _buildTimePicker({required String label, required bool isStart}) {
    final time = isStart ? _startTime : _endTime;
    final timeText = time != null ? time.format(context) : '--:-- --';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: slate400,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _pickTime(isStart: isStart),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: inputColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    timeText,
                    style: TextStyle(
                      color: time != null ? Colors.white : slate500,
                    ),
                  ),
                  Icon(Icons.schedule, color: slate500, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Description ---
  Widget _buildDescriptionField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DESCRIPTION',
            style: TextStyle(
              color: slate400,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: inputColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText:
                    'High-intensity interval training designed to boost your metabolism...',
                hintStyle: TextStyle(color: slate500),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Action Buttons ---
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          PrimaryButton(
            text: widget.isEditing ? 'Save Changes' : 'Create Class',
            icon: Icons.check_circle,
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _saveClass,
          ),
          if (widget.isEditing) ...[
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: _isLoading ? null : _deleteClass,
              icon: const Icon(Icons.delete, color: Colors.red, size: 18),
              label: const Text(
                'Delete Class',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
