import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mi_gym_flutter/providers/user_session.dart';
import 'package:mi_gym_flutter/screens/auth/register_page.dart';
import 'package:mi_gym_flutter/screens/admin/admin_page.dart';
import 'package:mi_gym_flutter/screens/client/home_page.dart';
import 'package:mi_gym_flutter/config/app_config.dart';
import 'package:mi_gym_flutter/theme/app_colors.dart';
import 'package:mi_gym_flutter/domain/usecases/login_usecase.dart';
import 'package:mi_gym_flutter/presentation/widgets/pulse_button.dart';
import 'package:mi_gym_flutter/presentation/widgets/pulse_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa todos los campos.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final loginUseCase = Provider.of<LoginUseCase>(context, listen: false);
      final user = await loginUseCase.execute(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user == null) {
        throw Exception('No se pudo encontrar el perfil del usuario.');
      }

      if (!mounted) return;

      final session = Provider.of<UserSession>(context, listen: false);
      session.setUser(user);

      if (user.isAdmin) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminPage()));
      } else {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage()));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.network(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuC_S4IVib1IFoHloqi4BP5sLC3Vs_UYdJZGnU_h2yPnFFSEdQfrAgSc5d0wQahe6YOFP6FPiJpJ0Tt23k0VU_UkAFRdmSV3WTX6RZGsHja0_MpemMCFcrb4uvlpxSASijP5gNEAqfg4R1vdqWiM-Hlu18u33P4YSrlZYVnM_Mjjeb6MmONYv4w9DFS4rLbYVD3698CPTEAB3_UrptOuLKEorTE_kJ7cQkdWqUcXDUXvu7gIU8Caz_sTDUau9UPrM_lU0V3Z9mCT2nQ3',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: AppColors.backgroundDark); // Fallback color
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
                    AppColors.backgroundDark,
                    AppColors.backgroundDark.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.bolt,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppConfig.appName.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 120),
                    const Text(
                      'Bienvenido de nuevo,\nAtleta.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Iniciá sesión para continuar tu entrenamiento.',
                      style: TextStyle(color: AppColors.slate400, fontSize: 16),
                    ),
                    const SizedBox(height: 32),

                    PulseTextField(
                      controller: _emailController,
                      label: 'Email',
                      hintText: 'usuario@${AppConfig.appName.toLowerCase()}.com',
                      prefixIcon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),
                    PulseTextField(
                      controller: _passwordController,
                      label: 'Contraseña',
                      hintText: '••••••••',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.slate500,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 24),

                    PulseButton(
                      text: 'Iniciar Sesión',
                      isLoading: _isLoading,
                      onPressed: _handleLogin,
                    ),
                    const SizedBox(height: 32),

                    // Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.slate800, thickness: 0.5)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'O CONTINUAR CON',
                            style: TextStyle(
                              color: AppColors.slate500,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: AppColors.slate800, thickness: 0.5)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Social Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.g_mobiledata,
                              color: Colors.white,
                              size: 28,
                            ),
                            label: const Text(
                              'Google',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppColors.slate900.withValues(alpha: 0.8),
                              side: const BorderSide(color: AppColors.slate800),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.apple,
                              color: Colors.white,
                              size: 28,
                            ),
                            label: const Text(
                              'Apple',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppColors.slate900.withValues(alpha: 0.8),
                              side: const BorderSide(color: AppColors.slate800),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),

                    // Bottom Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¿Nuevo en ${AppConfig.appName}? ',
                          style: const TextStyle(color: AppColors.slate400, fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'Register Now',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
