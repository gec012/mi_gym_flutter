import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mi_gym_flutter/domain/entities/user_entity.dart';
import 'package:mi_gym_flutter/domain/entities/booking_entity.dart';
import 'package:mi_gym_flutter/services/supabase_service.dart';
import 'package:mi_gym_flutter/screens/client/edit_profile_page.dart';
import 'package:mi_gym_flutter/theme/app_colors.dart';
import 'package:mi_gym_flutter/widgets/shared/change_password_sheet.dart';

class ProfilePage extends StatefulWidget {
  final UserEntity? user;
  final List<BookingEntity> allBookings;
  final VoidCallback onLogout;
  final VoidCallback? onRefresh;

  const ProfilePage({
    super.key,
    required this.user,
    required this.allBookings,
    required this.onLogout,
    this.onRefresh,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isUploading = false;

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

      await SupabaseService.updateUserProfile({'avatar_url': publicUrl});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil actualizada con éxito!'))
      );
      
      widget.onRefresh?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar foto: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final allBookings = widget.allBookings;
    
    final String fullName = user?.fullName ?? 'Athlete';
    final String? avatarUrl = user?.avatarUrl;
    final String role = user?.role.name.toUpperCase() ?? 'CLIENT';
    
    // Calcular estadísticas desde BookingEntity
    final int completedClasses = allBookings
        .where((b) => b.schedule != null && b.schedule!.startTime.isBefore(DateTime.now()))
        .length;
    
    final int totalMinutes = allBookings
        .where((b) => b.schedule != null && b.schedule!.startTime.isBefore(DateTime.now()))
        .fold(0, (sum, b) => sum + (b.schedule!.gymClass?.durationMinutes ?? 0));
    
    final String trainedHours = (totalMinutes / 60).toStringAsFixed(1);
    final int upcomingClasses = allBookings
        .where((b) => b.schedule != null && b.schedule!.startTime.isAfter(DateTime.now()))
        .length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Cabecera
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Perfil',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.slate800.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.settings, color: Colors.white, size: 22),
                ),
              ],
            ),
          ),

          // Perfil Hero
          const SizedBox(height: 10),
          Center(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    GestureDetector(
                      onTap: _isUploading ? null : _pickAndUploadImage,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            width: 4,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: AppColors.slate800,
                              backgroundImage: avatarUrl != null
                                  ? NetworkImage(avatarUrl)
                                  : const NetworkImage('https://images.unsplash.com/photo-1548690312-e3b507d8c110?q=80&w=300'),
                            ),
                            if (_isUploading)
                              const CircularProgressIndicator(color: AppColors.primary)
                            else
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(40),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 30),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'ACTIVO',
                        style: TextStyle(
                          color: AppColors.backgroundDark,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$role Member',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '#${user?.id.substring(0, 8) ?? 'athlete'}',
                  style: const TextStyle(
                    color: AppColors.slate400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Cards de Estadísticas
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                _buildStatItem('Clases', completedClasses.toString()),
                const SizedBox(width: 12),
                _buildStatItem('Próximas', upcomingClasses.toString()),
                const SizedBox(width: 12),
                _buildStatItem('Tiempo', '${trainedHours}h'),
              ],
            ),
          ),

          // Configuración
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AJUSTES DE CUENTA',
                  style: TextStyle(
                    color: AppColors.slate400,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSettingsItem(
                  Icons.person_outline, 
                  'Información Personal', 
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfilePage(
                        profile: user != null ? {
                          'id': user.id,
                          'full_name': user.fullName,
                          'avatar_url': user.avatarUrl,
                          'role': user.role,
                        } : null,
                        onProfileUpdated: () => widget.onRefresh?.call(),
                      ),
                    ),
                  )
                ),
                const SizedBox(height: 8),
                _buildSettingsItem(
                  Icons.lock_outline_rounded, 
                  'Cambiar Contraseña', 
                  () => showChangePasswordSheet(
                    context,
                    primaryColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceDark,
                  ),
                ),
                const SizedBox(height: 8),
                _buildSettingsItem(
                  Icons.credit_card, 
                  'Membresía y Pagos', 
                  () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Próximamente')))
                ),
                const SizedBox(height: 8),
                _buildSettingsItem(
                  Icons.history, 
                  'Historial de Entrenamiento', 
                  () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Próximamente')))
                ),
              ],
            ),
          ),

          // Botón Cerrar Sesión
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: GestureDetector(
              onTap: widget.onLogout,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                ),
                child: const Center(
                  child: Text(
                    'Cerrar Sesión',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.slate800.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: AppColors.slate500,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.slate800.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.slate200,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.slate500, size: 20),
          ],
        ),
      ),
    );
  }
}
