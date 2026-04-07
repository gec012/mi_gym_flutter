import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:mi_gym_flutter/providers/user_session.dart';
import 'package:mi_gym_flutter/services/supabase_service.dart';
import 'package:mi_gym_flutter/screens/auth/login_page.dart';
import 'package:mi_gym_flutter/widgets/shared/change_password_sheet.dart';

class AdminProfilePage extends StatefulWidget {
  final VoidCallback? onProfileUpdated;

  const AdminProfilePage({super.key, this.onProfileUpdated});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  // Admin brand colors
  static const Color _primary = Color(0xFF00BDD6);
  static const Color _bg = Color(0xFF0F2123);
  static const Color _surface = Color(0xFF1A2E31);

  final _nameController = TextEditingController();
  bool _isUploading = false;
  bool _isSaving = false;
  String? _avatarUrl;
  String _currentName = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final session = Provider.of<UserSession>(context, listen: false);
    _currentName = session.fullName ?? 'Admin';
    _avatarUrl = session.avatarUrl;
    _nameController.text = _currentName;
  }

  @override
  void dispose() {
    _nameController.dispose();
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
      await SupabaseService.updateUserProfile({'avatar_url': publicUrl});

      if (!mounted) return;
      setState(() => _avatarUrl = publicUrl);

      final session = Provider.of<UserSession>(context, listen: false);
      session.setAvatarUrl(publicUrl);

      widget.onProfileUpdated?.call();
      _showSnack('Foto actualizada con éxito 🎉');
    } catch (e) {
      _showSnack('Error al subir foto: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _saveName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      _showSnack('El nombre no puede estar vacío', isError: true);
      return;
    }
    setState(() => _isSaving = true);
    try {
      await SupabaseService.updateUserProfile({'full_name': newName});

      if (!mounted) return;
      final session = Provider.of<UserSession>(context, listen: false);
      session.setFullName(newName);

      setState(() => _currentName = newName);
      widget.onProfileUpdated?.call();
      _showSnack('Nombre actualizado correctamente');
    } catch (e) {
      _showSnack('Error al guardar: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : _primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar Sesión',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('¿Estás seguro que deseas salir de tu cuenta?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    await SupabaseService.signOut();
    if (!mounted) return;
    final session = Provider.of<UserSession>(context, listen: false);
    session.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = SupabaseService.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mi Perfil',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // ── Avatar ──────────────────────────────────────────────
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  GestureDetector(
                    onTap: _isUploading ? null : _pickAndUploadImage,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _primary, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: _primary.withValues(alpha: 0.25),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 64,
                            backgroundColor: _surface,
                            backgroundImage: _avatarUrl != null
                                ? NetworkImage(_avatarUrl!)
                                : const NetworkImage(
                                    'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e'),
                          ),
                          if (_isUploading)
                            const CircularProgressIndicator(color: _primary)
                          else
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(44),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Badge "ADMIN"
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'ADMIN',
                      style: TextStyle(
                        color: _bg,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Text(
              _currentName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 36),

            // ── Sección: Editar nombre ───────────────────────────────
            _sectionLabel('INFORMACIÓN DE CUENTA'),
            const SizedBox(height: 12),

            _buildFieldLabel('Nombre completo'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _primary.withValues(alpha: 0.2)),
                    ),
                    child: TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'Tu nombre',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
                        prefixIcon: Icon(Icons.person_outline, color: _primary, size: 20),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _isSaving ? null : _saveName,
                  child: Container(
                    width: 52,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isSaving
                        ? Padding(
                            padding: const EdgeInsets.all(14),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _bg),
                          )
                        : Icon(Icons.check_rounded, color: _bg, size: 24),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            _buildFieldLabel('Correo electrónico'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _primary.withValues(alpha: 0.1)),
              ),
              child: TextField(
                controller: TextEditingController(text: email),
                enabled: false,
                style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.email_outlined, color: _primary.withValues(alpha: 0.5), size: 20),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // ── Acciones ────────────────────────────────────────────
            _sectionLabel('ACCIONES'),
            const SizedBox(height: 12),

            _buildActionTile(
              icon: Icons.camera_alt_outlined,
              label: 'Cambiar foto de perfil',
              onTap: _isUploading ? null : _pickAndUploadImage,
              trailing: _isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _primary),
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            _buildActionTile(
              icon: Icons.lock_outline_rounded,
              label: 'Cambiar contraseña',
              onTap: () => showChangePasswordSheet(
                context,
                primaryColor: _primary,
                backgroundColor: _surface,
              ),
            ),

            const SizedBox(height: 32),

            // ── Cerrar sesión ────────────────────────────────────────
            GestureDetector(
              onTap: _confirmLogout,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 17),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.35)),
                  color: Colors.redAccent.withValues(alpha: 0.05),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Cerrar Sesión',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.35),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _primary.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: _primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }
}
