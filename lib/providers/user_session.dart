import 'package:flutter/foundation.dart';
import 'package:mi_gym_flutter/domain/entities/user_entity.dart';
import 'package:mi_gym_flutter/services/supabase_service.dart';

/// Estado global que mantiene la sesión del usuario y su rol.
/// Accesible desde cualquier parte de la app con Provider.
class UserSession extends ChangeNotifier {
  UserEntity? _userEntity;
  bool _isLoading = false;
  String? _error;

  // --- Getters ---
  UserEntity? get userEntity => _userEntity;
  String? get role => _userEntity?.role.name;
  String? get userId => _userEntity?.id;
  String? get fullName => _userEntity?.fullName;
  String? get avatarUrl => _userEntity?.avatarUrl;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isAdmin => _userEntity?.role == UserRole.admin;
  bool get isClient => _userEntity?.role == UserRole.client;
  bool get isLoggedIn => _userEntity != null;

  /// Establece manualmente el usuario (ej. después de login con UseCase)
  void setUser(UserEntity user) {
    _userEntity = user;
    notifyListeners();
  }

  /// Actualiza solo el nombre completo del usuario en sesión.
  void setFullName(String name) {
    if (_userEntity == null) return;
    _userEntity = UserEntity(
      id: _userEntity!.id,
      fullName: name,
      avatarUrl: _userEntity!.avatarUrl,
      role: _userEntity!.role,
      email: _userEntity!.email,
    );
    notifyListeners();
  }

  /// Actualiza solo la URL del avatar del usuario en sesión.
  void setAvatarUrl(String url) {
    if (_userEntity == null) return;
    _userEntity = UserEntity(
      id: _userEntity!.id,
      fullName: _userEntity!.fullName,
      avatarUrl: url,
      role: _userEntity!.role,
      email: _userEntity!.email,
    );
    notifyListeners();
  }

  /// Carga el perfil del usuario autenticado desde Supabase.
  /// Debe llamarse justo después de un login exitoso.
  @Deprecated('Use setUser with entities from domain layer')
  Future<void> loadUserProfile(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final profile = await SupabaseService.getUserProfile(userId);

      if (profile == null) {
        _error = 'Profile not found for this user. Please contact support.';
        _userEntity = null;
      } else {
        // Mapeo rudimentario para compatibilidad si aún se usa este método
        _userEntity = UserEntity(
          id: userId,
          fullName: profile['full_name'] as String? ?? '',
          avatarUrl: profile['avatar_url'] as String?,
          role: profile['role'] == 'admin' ? UserRole.admin : UserRole.client,
          email: '', // No disponible en el perfil usualmente
        );
      }
    } catch (e) {
      _error = 'Failed to load profile: ${e.toString()}';
      _userEntity = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Limpia la sesión (para logout).
  void clear() {
    _userEntity = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
