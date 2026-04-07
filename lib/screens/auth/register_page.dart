import 'package:flutter/material.dart';
import 'package:mi_gym_flutter/screens/auth/login_page.dart';
import 'package:mi_gym_flutter/screens/client/home_page.dart';
import 'package:mi_gym_flutter/services/supabase_service.dart';
import 'package:mi_gym_flutter/config/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mi_gym_flutter/theme/app_colors.dart';
import 'package:mi_gym_flutter/widgets/shared/primary_button.dart';
import 'package:mi_gym_flutter/utils/validators.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  final Color primaryColor = AppColors.primary;
  final Color backgroundDark = AppColors.backgroundDark;
  final Color slate900 = AppColors.slate900;
  final Color slate800 = AppColors.slate800;
  final Color slate700 = AppColors.slate700;
  final Color slate500 = AppColors.slate500;
  final Color slate400 = AppColors.slate400;
  final Color slate300 = AppColors.slate300;

  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final nameError = Validators.required(_nameController.text, 'El nombre es obligatorio');
    final emailError = Validators.email(_emailController.text);
    final passwordError = Validators.password(_passwordController.text, 
      minLength: 8,
      requireUppercase: true,
      requireLowercase: true,
      requireNumber: true,
    );

    if (nameError != null || emailError != null || passwordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(nameError ?? emailError ?? passwordError!),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await SupabaseService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _nameController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please check your email.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              color: slate300,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          obscureText: isPassword && _obscurePassword,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: slate500, fontSize: 16),
            prefixIcon: Icon(icon, color: slate500, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: slate500,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: slate900.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(vertical: 20),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: slate700.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: primaryColor),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundDark,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.network(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuC_S4IVib1IFoHloqi4BP5sLC3Vs_UYdJZGnU_h2yPnFFSEdQfrAgSc5d0wQahe6YOFP6FPiJpJ0Tt23k0VU_UkAFRdmSV3WTX6RZGsHja0_MpemMCFcrb4uvlpxSASijP5gNEAqfg4R1vdqWiM-Hlu18u33P4YSrlZYVnM_Mjjeb6MmONYv4w9DFS4rLbYVD3698CPTEAB3_UrptOuLKEorTE_kJ7cQkdWqUcXDUXvu7gIU8Caz_sTDUau9UPrM_lU0V3Z9mCT2nQ3',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: backgroundDark); // Fallback color
              },
            ),
          ),
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    backgroundDark,
                    backgroundDark.withValues(alpha: 0.9),
                    backgroundDark.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.bolt,
                          color: backgroundDark,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppConfig.appName.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 120),
                  // Main Form
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                        letterSpacing: -0.5,
                        fontFamily: 'Lexend',
                      ),
                      children: [
                        const TextSpan(
                          text: 'Join the\n',
                          style: TextStyle(color: Colors.white),
                        ),
                        TextSpan(
                          text: 'Elite.',
                          style: TextStyle(color: primaryColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Start your transformation today.',
                    style: TextStyle(color: slate400, fontSize: 16),
                  ),
                  const SizedBox(height: 40),

                  // Full Name Field
                  _buildField(
                    label: 'Nombre Completo',
                    hint: 'Juan Pérez',
                    icon: Icons.person_outline,
                    controller: _nameController,
                  ),
                  const SizedBox(height: 20),

                  // Email Field
                  _buildField(
                    label: 'Correo Electrónico',
                    hint: 'atleta@${AppConfig.appName.toLowerCase()}.com',
                    icon: Icons.mail_outline,
                    controller: _emailController,
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  _buildField(
                    label: 'Contraseña',
                    hint: '........',
                    icon: Icons.lock_outline,
                    isPassword: true,
                    controller: _passwordController,
                  ),
                  const SizedBox(height: 32),

                  // Create Account Button
                  PrimaryButton(
                    text: 'Crear Cuenta',
                    icon: Icons.arrow_forward,
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _handleRegister,
                  ),

                  const SizedBox(height: 60),

                  // Bottom Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿Ya tenés cuenta? ',
                        style: TextStyle(color: slate400, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                          );
                        },
                        child: Text(
                          'Iniciar Sesión',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 14,
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
        ],
      ),
    );
  }
}
