class Validators {
  static String? required(String? value, [String message = 'Este campo es obligatorio']) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  static String? email(String? value, [String message = 'Ingresa un email válido']) {
    if (value == null || value.trim().isEmpty) {
      return 'El email es obligatorio';
    }
    
    // Expresión regular estándar para atrapar emails
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return message;
    }
    return null;
  }

  static String? password(String? value, {
    int minLength = 8,
    bool requireUppercase = true,
    bool requireLowercase = true,
    bool requireNumber = true,
    bool requireSpecialChar = false,
  }) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (value.length < minLength) {
      return 'Debe tener al menos $minLength caracteres';
    }
    if (requireUppercase && !value.contains(RegExp(r'[A-Z]'))) {
      return 'Debe contener al menos una mayúscula';
    }
    if (requireLowercase && !value.contains(RegExp(r'[a-z]'))) {
      return 'Debe contener al menos una minúscula';
    }
    if (requireNumber && !value.contains(RegExp(r'[0-9]'))) {
      return 'Debe contener al menos un número';
    }
    if (requireSpecialChar && !value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Debe contener al menos un carácter especial';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value != null && value.isNotEmpty) {
      // Remover espacios y caracteres no numéricos excepto el + para validar
      final phoneValid = RegExp(r'^\+?[0-9\s\-\(\)]+$').hasMatch(value);
      if (!phoneValid) {
        return 'Ingresa un formato de teléfono válido';
      }
    }
    return null;
  }
}
