import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mi_gym_flutter/providers/user_session.dart';
import 'package:mi_gym_flutter/screens/auth/login_page.dart';
import 'package:mi_gym_flutter/screens/admin/admin_profile_page.dart';
import 'package:mi_gym_flutter/screens/admin/admin_calendar_page.dart';
import 'package:mi_gym_flutter/screens/admin/create_edit_class_page.dart';
import 'package:mi_gym_flutter/screens/admin/tabs/admin_classes_page.dart';
import 'package:mi_gym_flutter/screens/admin/tabs/admin_users_page.dart';
import 'package:mi_gym_flutter/services/supabase_service.dart';
import 'package:mi_gym_flutter/models/class_model.dart';
import 'package:mi_gym_flutter/models/schedule_model.dart';
import 'package:mi_gym_flutter/models/category_model.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final Color primaryColor = const Color(0xFF00BDD6);
  final Color backgroundDark = const Color(0xFF0F2123);
  final Color surfaceColor = const Color(0xFF1A2E31);
  final Color accentGreen = const Color(0xFF0BDA54);
  final Color slate500 = const Color(0xFF64748B);
  final Color slate400 = const Color(0xFF94A3B8);
  final Color slate300 = const Color(0xFFCBD5E1);
  final Color slate800 = const Color(0xFF1E293B);

  int _currentIndex = 0;
  String selectedCategory = 'Todas';
  late Future<Map<String, dynamic>> _dashboardData;

  @override
  void initState() {
    super.initState();

    // GUARD: Protección de ruta mediante PostFrameCallback (hace el efecto de un Middleware)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = Provider.of<UserSession>(context, listen: false);

      // Si el rol no es admin, abortamos el renderizado y lo pateamos al Login
      if (!session.isAdmin) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
      }
    });

    _dashboardData = SupabaseService.getAdminDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundDark,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _dashboardData = SupabaseService.getAdminDashboardData();
                    }),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          final schedulesCount = data['schedules_count'] as int;
          final liveSessions = data['live_sessions'] as List<ScheduleModel>;
          final upcomingSchedules =
              data['upcoming_schedules'] as List<ScheduleModel>;
          final categories = data['categories'] as List<CategoryModel>;
          final classes = data['classes'] as List<ClassModel>;

          return SafeArea(
            child: _buildBodyContent(
              schedulesCount,
              liveSessions,
              upcomingSchedules,
              categories,
              classes,
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBodyContent(
    int schedulesCount,
    List<ScheduleModel> liveSessions,
    List<ScheduleModel> upcomingSchedules,
    List<CategoryModel> categories,
    List<ClassModel> classes,
  ) {
    if (_currentIndex == 1) {
      return AdminClassesPage(
        categories: categories,
        classes: classes,
        onRefresh: () => setState(() {
          _dashboardData = SupabaseService.getAdminDashboardData();
        }),
      );
    }

    if (_currentIndex == 2) {
      return const AdminUsersPage();
    }

    // Default to Dashboard Tab
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildHeader(),
          ),
          const SizedBox(height: 24),

          // Performance Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'GYM PERFORMANCE',
              style: TextStyle(
                color: slate500,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Scheduled Classes',
                    schedulesCount.toString(),
                    '+2',
                    Icons.calendar_today,
                    true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Occupancy Rate',
                    '92%',
                    '+5%',
                    Icons.group,
                    true,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildQuickActions(),
          ),

          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildHappeningNow(liveSessions),
          ),

          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildUpcomingSchedule(upcomingSchedules),
          ),
          const SizedBox(height: 100), // spacer for bottom nav
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceColor,
        title: const Text(
          'Cerrar Sesión',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '¿Estás seguro que deseas salir de tu cuenta?',
          style: TextStyle(color: Colors.white70),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancelar', style: TextStyle(color: slate400)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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

  Widget _buildHeader() {
    final session = Provider.of<UserSession>(context);
    final avatarUrl = session.avatarUrl;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Admin Portal',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminProfilePage(
                onProfileUpdated: () => setState(() {}),
              ),
            ),
          ),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryColor, width: 2),
              image: DecorationImage(
                image: NetworkImage(
                  avatarUrl ?? 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String trend,
    IconData icon,
    bool isIncrease,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: slate300,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: primaryColor, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  Icon(
                    isIncrease ? Icons.trending_up : Icons.trending_down,
                    color: accentGreen,
                    size: 14,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    trend,
                    style: TextStyle(
                      color: accentGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK ACTIONS',
          style: TextStyle(
            color: slate500,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Create Class',
                Icons.add_circle,
                true,
                onTap: () => _navigateToCreateClass(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildActionButton('Calendar', Icons.event, false, onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminCalendarPage()),
              );
            })),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    bool isPrimary, {
    VoidCallback? onTap,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isPrimary ? primaryColor : surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: isPrimary
            ? null
            : Border.all(color: primaryColor.withValues(alpha: 0.2)),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isPrimary ? backgroundDark : Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isPrimary ? backgroundDark : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCreateClass() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CreateEditClassPage()));
    if (result == true) {
      setState(() {
        _dashboardData = SupabaseService.getAdminDashboardData();
      });
    }
  }

  void _navigateToEditClass(ClassModel classData) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateEditClassPage(classData: classData),
      ),
    );
    if (result == true) {
      setState(() {
        _dashboardData = SupabaseService.getAdminDashboardData();
      });
    }
  }

  Widget _buildHappeningNow(List<ScheduleModel> sessions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'HAPPENING NOW',
              style: TextStyle(
                color: slate500,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.5,
              ),
            ),
            if (sessions.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (sessions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Center(
              child: Text(
                'No active classes right now',
                style: TextStyle(color: slate500),
              ),
            ),
          )
        else
          ...sessions.map((s) => _buildLiveCard(s)),
      ],
    );
  }

  Widget _buildLiveCard(ScheduleModel session) {
    final className = session.classData?.name ?? 'HIIT Session';
    final instructorName = session.instructor?.name ?? 'Instructor';

    final booked = session.bookedCount;
    final capacity = session.capacity;

    // Safety check just in case capacity is 0
    final double fillPercentage = capacity > 0 ? (booked / capacity) : 0;

    final imageUrl =
        session.classData?.imageUrl ??
        'https://images.unsplash.com/photo-1517836357463-d25dfeac3438';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 200,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Image with gradient
          Positioned.fill(child: Image.network(imageUrl, fit: BoxFit.cover)),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.9),
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Content Box at the bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          className,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.person, color: primaryColor, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Coach $instructorName',
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$booked/$capacity Spots',
                          style: TextStyle(
                            color: backgroundDark,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 96,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: fillPercentage > 1
                                ? 1
                                : fillPercentage,
                            child: Container(
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingSchedule(List<ScheduleModel> schedules) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'UPCOMING SCHEDULE',
          style: TextStyle(
            color: slate500,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        if (schedules.isEmpty)
          Center(
            child: Text(
              'Nothing scheduled soon',
              style: TextStyle(color: slate500),
            ),
          )
        else
          ...schedules.map((s) => _buildScheduleItem(s)),
      ],
    );
  }

  Widget _buildScheduleItem(ScheduleModel schedule) {
    final className = schedule.classData?.name ?? 'Class';
    final instructor = schedule.instructor?.name ?? 'Instructor';
    final startTime = schedule.startTime;

    final amPm = startTime.hour >= 12 ? 'PM' : 'AM';
    final hour = startTime.hour > 12
        ? startTime.hour - 12
        : (startTime.hour == 0 ? 12 : startTime.hour);
    final min = startTime.minute.toString().padLeft(2, '0');
    final isFull = schedule.bookedCount >= schedule.capacity;

    return GestureDetector(
      onTap: () {
        if (schedule.classData != null) {
          _navigateToEditClass(schedule.classData!);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryColor.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$hour:$min',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    amPm,
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
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
                    className,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Main Studio • $instructor',
                    style: TextStyle(color: slate400, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isFull)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: slate800,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Full',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(color: primaryColor.withValues(alpha: 0.1)),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(0, Icons.home_rounded, 'HOME'),
            _buildNavItem(1, Icons.calendar_month_rounded, 'CLASSES'),
            _buildNavItem(2, Icons.group_rounded, 'USERS'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isActive = _currentIndex == index;
    final color = isActive ? primaryColor : slate400;

    return GestureDetector(
      onTap: () {
        if (index == 3) {
          _confirmLogout();
        } else {
          setState(() => _currentIndex = index);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
