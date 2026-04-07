import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mi_gym_flutter/providers/user_session.dart';
import 'package:mi_gym_flutter/screens/auth/login_page.dart';
import 'package:mi_gym_flutter/screens/client/tabs/clases_page.dart';
import 'package:mi_gym_flutter/domain/entities/category_entity.dart';
import 'package:mi_gym_flutter/domain/entities/gym_class_entity.dart';
import 'package:mi_gym_flutter/domain/entities/schedule_entity.dart';
import 'package:mi_gym_flutter/domain/usecases/get_home_data_usecase.dart';
import 'package:mi_gym_flutter/domain/usecases/login_usecase.dart';
import 'package:mi_gym_flutter/presentation/helpers/intensity_helper.dart';
import 'package:mi_gym_flutter/screens/client/class_details_page.dart';
import 'package:mi_gym_flutter/screens/client/tabs/my_bookings_page.dart';
import 'package:mi_gym_flutter/screens/client/tabs/profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mi_gym_flutter/theme/app_colors.dart';
import 'package:mi_gym_flutter/widgets/pulse/pulse_card.dart';
import 'package:mi_gym_flutter/widgets/pulse/pulse_button.dart';
import 'package:mi_gym_flutter/widgets/pulse/pulse_chip.dart';
import 'package:mi_gym_flutter/widgets/shared/status_badge.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedCategory = 'Todas';
  int _currentIndex = 0;

  late Future<HomeData> _homeData;
  RealtimeChannel? _bookingsSubscription;

  @override
  void initState() {
    super.initState();
    _homeData = _fetchHomeData();
    _setupRealtime();
  }

  void _setupRealtime() {
    _bookingsSubscription = Supabase.instance.client
        .channel('public:bookings')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          callback: (payload) {
            if (mounted) {
              setState(() {
                _homeData = _fetchHomeData();
              });
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _bookingsSubscription?.unsubscribe();
    super.dispose();
  }

  Future<HomeData> _fetchHomeData() async {
    final useCase = context.read<GetHomeDataUseCase>();
    return await useCase.execute();
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text(
          'Cerrar Sesión',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Estás seguro que deseas salir de tu cuenta?',
          style: TextStyle(color: AppColors.slate400),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancelar', style: TextStyle(color: AppColors.slate500)),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: PulseButton(
              width: 100,
              label: 'Salir',
              onPressed: () {
                Navigator.of(ctx).pop();
                _logout();
              },
              backgroundColor: AppColors.error,
            ),
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

    final loginUseCase = context.read<LoginUseCase>();
    await loginUseCase.logout();
    
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
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: FutureBuilder<HomeData>(
        future: _homeData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Error al cargar los datos',
                      style: TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.slate500, fontSize: 13),
                    ),
                    const SizedBox(height: 32),
                    PulseButton(
                      label: 'Reintentar',
                      onPressed: () {
                        setState(() {
                          _homeData = _fetchHomeData();
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          final homeData = snapshot.data!;

          return SafeArea(
            bottom: false,
            child: _buildBodyContent(homeData),
          );
        },
      ),
      extendBody: true,
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBodyContent(HomeData data) {
    final userName = data.profile?.fullName?.split(' ')[0] ?? 'Athlete';
    final avatarUrl = data.profile?.avatarUrl;

    if (_currentIndex == 1) {
      return ClasesPage(
        categories: data.categories,
        schedules: data.schedules,
        onRefresh: () => setState(() {
          _homeData = _fetchHomeData();
        }),
      );
    }

    if (_currentIndex == 3) {
      return MyBookingsPage(
        bookings: data.userBookings,
        onRefresh: () => setState(() {
          _homeData = _fetchHomeData();
        }),
      );
    }

    if (_currentIndex == 4) {
      return ProfilePage(
        user: data.profile!,
        allBookings: data.userBookings,
        onLogout: _confirmLogout,
        onRefresh: () {
          setState(() {
            _homeData = _fetchHomeData();
          });
        },
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(userName, avatarUrl),
          _buildActivityStats(),
          _buildCategoryFilters(data.categories),
          _buildFeaturedClasses(data.schedules, data.categories),
          _buildUpcomingSessions(data.schedules),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildHeader(String name, String? avatarUrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: avatarUrl != null
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(Icons.person, color: AppColors.slate500),
                    )
                  : Image.network(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuDYXtabB1L84-NJkHCsk4NvWccPTfet_1Imn1gQ0cGTBzY7UBC9-lFCHMyD4VWmKr_yvxi01ToMcN3j0iW9gbSTuTfg24wu1OIChxRBi2wj-0fKC2naeATRkafhpL4CJNOQ0AP1-PL67aMvMkRzrXXUQ_UI21wBJCrG7OO8tIltIbcAoIcERRqfDCnsPphGcGETQJOQ97aNM0lIVC8GDY90i5RRQY-Ip-wUTF9qRsiUfiMCMYYCa8k0RNFCz30yxIWK9rg4AaKeEGCo',
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Hola, $name 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '¿Listo para entrenar hoy?',
                  style: TextStyle(color: AppColors.slate400, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.slate800),
            ),
            child: const Icon(
              Icons.notifications_none,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          _buildStatCard('Pasos', '8.432', Icons.directions_walk, AppColors.primary),
          const SizedBox(width: 10),
          _buildStatCard('Calorías', '450', Icons.local_fire_department, Colors.orange),
          const SizedBox(width: 10),
          _buildStatCard('Entrenos', '12', Icons.fitness_center, Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: PulseCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: AppColors.slate500,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(text: value),
                  if (label == 'Calorías')
                    TextSpan(
                      text: ' kcal',
                      style: TextStyle(
                        color: AppColors.slate500,
                        fontSize: 10,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilters(List<CategoryEntity> categories) {
    final catList = ['Todas', ...categories.map((c) => c.name)];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: catList.map((cat) {
            bool isActive = selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: PulseChip(
                label: cat,
                isActive: isActive,
                onTap: () => setState(() => selectedCategory = cat),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFeaturedClasses(List<ScheduleEntity> schedules, List<CategoryEntity> categories) {
    var featured = schedules
        .where((s) => !s.isUserBooked && s.startTime.isAfter(DateTime.now()))
        .toList();

    if (selectedCategory != 'Todas') {
      final targetCat = categories.firstWhere(
        (c) => c.name == selectedCategory,
        orElse: () => CategoryEntity(id: '', name: ''),
      );
      if (targetCat.id.isNotEmpty) {
        featured = featured
            .where((s) => s.gymClass?.categoryId == targetCat.id)
            .toList();
      }
    }

    if (featured.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Text(
          'No hay clases disponibles en $selectedCategory',
          style: TextStyle(color: AppColors.slate500, fontSize: 14),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Clases Destacadas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Ver todas',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: featured.take(5).map((schedule) {
              final cls = schedule.gymClass;
              if (cls == null) return const SizedBox.shrink();
              final timeStr =
                  '${schedule.startTime.hour.toString().padLeft(2, '0')}:${schedule.startTime.minute.toString().padLeft(2, '0')}';
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildFeaturedCard(schedule, cls, timeStr),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCard(ScheduleEntity schedule, GymClassEntity cls, String timeStr) {
    final isFull = schedule.bookedCount >= schedule.capacity;
    final isBookedByUser = schedule.isUserBooked;
    final intensityColor = IntensityHelper.getColor(cls.intensity);
    final intensityLabel = IntensityHelper.getLabel(cls.intensity);

    return Container(
      width: 260,
      height: 360,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        image: DecorationImage(
          image: NetworkImage(cls.imageUrl),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.2),
            BlendMode.darken,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            stops: const [0.0, 0.4, 1.0],
            colors: [
              Colors.black.withValues(alpha: 0.95),
              Colors.black.withValues(alpha: 0.3),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            StatusBadge(
              text: intensityLabel,
              color: intensityColor,
            ),
            const SizedBox(height: 8),
            Text(
              cls.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.white70, size: 12),
                const SizedBox(width: 4),
                Text(
                  timeStr,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.timer_outlined, color: Colors.white70, size: 12),
                const SizedBox(width: 4),
                Text(
                  '${cls.durationMinutes} min',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 16),
            PulseButton(
              label: isBookedByUser ? 'VER RES.' : (isFull ? 'LLENO' : 'Reservar'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ClassDetailsPage(
                      scheduleId: schedule.id,
                      onRefresh: () {
                        setState(() {
                          _homeData = _fetchHomeData();
                        });
                      },
                    ),
                  ),
                );
              },
              isSecondary: isBookedByUser,
              backgroundColor: isBookedByUser ? Colors.transparent : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingSessions(List<ScheduleEntity> schedules) {
    final mySessions = schedules
        .where((s) => s.isUserBooked && s.startTime.isAfter(DateTime.now()))
        .toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mis Próximas Clases',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (mySessions.isEmpty)
            PulseCard(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.event_available, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Sin clases reservadas',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Reservá una clase en la pestaña "Clases"\npara verla aparecer aquí.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.slate500, fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            )
          else
            ...mySessions.map((schedule) {
              final cls = schedule.gymClass;
              if (cls == null) return const SizedBox.shrink();

              final timeStr =
                  '${schedule.startTime.hour.toString().padLeft(2, '0')}:${schedule.startTime.minute.toString().padLeft(2, '0')}';

              final now = DateTime.now();
              String dayStr = 'Hoy';
              if (schedule.startTime.day != now.day) {
                final diff = schedule.startTime.difference(now).inDays;
                if (diff == 0 || (diff == 1 && schedule.startTime.day - now.day == 1)) {
                  dayStr = 'Mañana';
                } else {
                  dayStr = '${schedule.startTime.day}/${schedule.startTime.month}';
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSessionItem(
                  cls.name,
                  'Coach ${schedule.instructor?.name ?? ''}',
                  dayStr,
                  timeStr,
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSessionItem(String title, String coach, String day, String time) {
    return PulseCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day,
                  style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                Text(
                  time,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  coach,
                  style: TextStyle(color: AppColors.slate500, fontSize: 13),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.slate500),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 85,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: AppColors.slate800.withValues(alpha: 0.5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_filled, 'Inicio'),
          _buildNavItem(1, Icons.calendar_month, 'Clases'),
          _buildNavItem(3, Icons.event_available, 'Reservas'),
          _buildNavItem(4, Icons.person_outline, 'Perfil'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isActive = _currentIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _currentIndex = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.primary : AppColors.slate500,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.primary : AppColors.slate500,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
