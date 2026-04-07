import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mi_gym_flutter/theme/app_colors.dart';
import 'package:mi_gym_flutter/widgets/shared/glass_card.dart';
import 'package:mi_gym_flutter/widgets/shared/status_badge.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final Color primaryColor = AppColors.primary;
  final Color backgroundDark = AppColors.backgroundDark;
  
  final Color emerald500 = AppColors.success;
  final Color rose500 = AppColors.error;
  final Color amber500 = AppColors.warning;
  final Color slate500 = AppColors.slate500;
  final Color slate400 = AppColors.slate400;
  final Color slate300 = AppColors.slate300;
  final Color surfaceDark = AppColors.surfaceDark;
  final Color slate800 = AppColors.slate800;

  late Future<Map<String, dynamic>> _pageDataFuture;
  String _searchQuery = '';
  String _selectedFilter = 'Todas las Clases';
  String _selectedRoleFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    _pageDataFuture = _fetchPageData();
  }

  Future<Map<String, dynamic>> _fetchPageData() async {
    final client = Supabase.instance.client;

    // 1. Fetch Clients
    final usersResp = await client
        .from('profiles')
        .select()
        .order('full_name', ascending: true);
    final List<Map<String, dynamic>> users = List<Map<String, dynamic>>.from(usersResp);

    // 2. Fetch today's bookings for everyone
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59).toUtc().toIso8601String();

    final bookingsResp = await client
        .from('bookings')
        .select('*, class_schedules!inner(start_time, classes(name, categories(name)))')
        .gte('class_schedules.start_time', startOfDay)
        .lte('class_schedules.start_time', endOfDay);
        
    final List<Map<String, dynamic>> bookings = List<Map<String, dynamic>>.from(bookingsResp);

    // Categories string set for the dynamic filters
    final Set<String> categoriesSet = {'Todas las Clases'};

    // Process bookings and map to users
    int presentesCount = 0;
    int waitlistCount = 0;

    for (var b in bookings) {
      if (b['is_present'] == true) presentesCount++;
      if (b['status'] == 'waitlist') waitlistCount++;
      
      final schedule = b['class_schedules'];
      if (schedule != null) {
        final className = schedule['classes']['name'];
        categoriesSet.add(className); // Adding class names to filters
      }
    }

    // Attach current activity to user
    for (var u in users) {
      u['current_status'] = null; // Default none
      
      // Find the user's latest booking for today
      final userBookings = bookings.where((b) => b['user_id'] == u['id']).toList();
      if (userBookings.isNotEmpty) {
        // Sort by start_time descending to get the most relevant/latest one
        userBookings.sort((a, b) {
          final timeA = DateTime.parse(a['class_schedules']['start_time']);
          final timeB = DateTime.parse(b['class_schedules']['start_time']);
          return timeB.compareTo(timeA); 
        });
        
        final latestBooking = userBookings.first;
        final scheduleTime = DateTime.parse(latestBooking['class_schedules']['start_time']).toLocal();
        final formattedTime = '${scheduleTime.hour > 12 ? scheduleTime.hour - 12 : (scheduleTime.hour == 0 ? 12 : scheduleTime.hour)}:${scheduleTime.minute.toString().padLeft(2, '0')} ${scheduleTime.hour >= 12 ? 'PM' : 'AM'}';
        
        if (latestBooking['is_present'] == true) {
          u['current_status'] = 'PRESENTE';
          u['status_sub'] = formattedTime;
          u['status_color'] = emerald500;
        } else if (latestBooking['status'] == 'waitlist') {
          u['current_status'] = 'RESERVADO';
          u['status_sub'] = 'Waitlist ($formattedTime)';
          u['status_color'] = amber500;
        } else if (latestBooking['status'] == 'cancelled') {
          u['current_status'] = 'CANCELADO';
          u['status_sub'] = 'No asiste';
          u['status_color'] = slate500;
        } else {
          u['current_status'] = 'CONFIRMADO';
          u['status_sub'] = formattedTime;
          u['status_color'] = primaryColor;
        }
        
        u['class_name'] = latestBooking['class_schedules']['classes']['name'];
      }
    }

    return {
      'users': users,
      'kpi_presentes': presentesCount,
      'kpi_waitlist': waitlistCount,
      'filters': categoriesSet.toList(),
    };
  }

  void _refreshData() {
    setState(() {
      _pageDataFuture = _fetchPageData();
    });
  }

  Future<void> _toggleUserRole(String userId, String newRole) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await Supabase.instance.client
          .from('profiles')
          .update({'role': newRole})
          .eq('id', userId);

      if (!mounted) return;
      Navigator.of(context).pop(); // close dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rol actualizado a ${newRole.toUpperCase()}'),
          backgroundColor: emerald500,
        ),
      );

      _refreshData();
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // close dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar: $e'),
          backgroundColor: rose500,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, 
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: primaryColor,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Icon(Icons.add, color: backgroundDark, size: 32),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _pageDataFuture,
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
                        Text('Error loading data: ${snapshot.error}', style: TextStyle(color: slate400)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: backgroundDark,
                          ),
                          child: const Text('Retry'),
                        )
                      ],
                    ),
                  );
                }

                final data = snapshot.data!;
                final List<Map<String, dynamic>> allUsers = data['users'];
                final List<String> availableFilters = data['filters'];
                final int kpiPresentes = data['kpi_presentes'];
                final int kpiWaitlist = data['kpi_waitlist'];

                // Filtering users by Search Query and Selected Filter
                final filteredUsers = allUsers.where((user) {
                  // Search Match
                  final name = (user['full_name'] ?? '').toString().toLowerCase();
                  final phone = (user['phone'] ?? '').toString().toLowerCase();
                  final query = _searchQuery.toLowerCase();
                  final matchesSearch = name.contains(query) || phone.contains(query);
                  
                  // Filter Match
                  bool matchesFilter = true;
                  if (_selectedFilter != 'Todas las Clases') {
                    matchesFilter = user['class_name'] == _selectedFilter;
                  }

                  // Role Filter Match
                  bool matchesRole = true;
                  if (_selectedRoleFilter != 'Todos') {
                    final role = user['role'] ?? 'client';
                    if (_selectedRoleFilter == 'Administradores') {
                      matchesRole = role == 'admin';
                    } else if (_selectedRoleFilter == 'Clientes') {
                      matchesRole = role == 'client';
                    }
                  }

                  return matchesSearch && matchesFilter && matchesRole;
                }).toList();

                return RefreshIndicator(
                  onRefresh: () async {
                    _refreshData();
                    await _pageDataFuture;
                  },
                  color: primaryColor,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _buildKPIs(allUsers.length, kpiPresentes, kpiWaitlist)),
                      SliverToBoxAdapter(child: _buildSearchBar()),
                      SliverToBoxAdapter(child: _buildUnifiedFilters(availableFilters)),
                      
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                          child: Text(
                            '${_selectedRoleFilter.toUpperCase()} (${filteredUsers.length})',
                            style: TextStyle(
                              color: slate500,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                      if (filteredUsers.isEmpty)
                        SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 60),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_off_outlined, color: slate500, size: 64),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isEmpty 
                                        ? 'No hay usuarios en esta categoría' 
                                        : 'No hay usuarios que coincidan con la búsqueda',
                                    style: TextStyle(color: slate400, fontSize: 15),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return _buildUserCard(filteredUsers[index]);
                              },
                              childCount: filteredUsers.length,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.group, color: primaryColor, size: 30),
              const SizedBox(width: 12),
              const Text(
                'Gestión de Usuarios',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
            ),
            child: Icon(Icons.notifications_none, color: primaryColor, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildKPIs(int totalUsers, int presentes, int waitlist) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  'Inscritos',
                  totalUsers.toString(),
                  null, // Empty trend to match design real-time data feel
                  true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKPICard(
                  'Presentes',
                  presentes.toString(),
                  null,
                  false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildKPICard(
            'Lista Espera',
            waitlist.toString(),
            null,
            true,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard(String title, String value, String? trend, bool isIncrease, {bool isFullWidth = false}) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: slate500,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isIncrease 
                        ? emerald500.withValues(alpha: 0.1) 
                        : rose500.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(
                      color: isIncrease ? emerald500 : rose500,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: TextField(
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Buscar cliente por nombre o teléfono...',
            hintStyle: TextStyle(color: slate500),
            prefixIcon: Icon(Icons.search, color: slate400),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildUnifiedFilters(List<String> classFilters) {
    final roles = ['Todos', 'Clientes', 'Administradores'];
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Filtros de Búsqueda',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'ROL DEL USUARIO',
              style: TextStyle(
                color: slate500,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: roles.map((role) {
                final isSelected = role == _selectedRoleFilter;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedRoleFilter = role);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor : surfaceDark,
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected ? null : Border.all(color: slate800.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      role,
                      style: TextStyle(
                        color: isSelected ? Colors.white : slate400,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            if (classFilters.length > 1) ...[
              const SizedBox(height: 24),
              Text(
                'CLASE REGISTRADA (HOY)',
                style: TextStyle(
                  color: slate500,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: classFilters.map((filter) {
                  final isSelected = filter == _selectedFilter;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedFilter = filter);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : surfaceDark,
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected ? null : Border.all(color: slate800.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            filter,
                            style: TextStyle(
                              color: isSelected ? Colors.white : slate400,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          if (!isSelected && filter != 'Todas las Clases') ...[
                            const SizedBox(width: 4),
                            Icon(Icons.expand_more, color: slate500, size: 16),
                          ]
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final name = user['full_name'] ?? 'Usuario';
    final avatarUrl = user['avatar_url'];
    // For visual aesthetic like the design, fake email if no phone/email is perfectly formatted
    final email = user['phone'] != null && user['phone'].toString().isNotEmpty 
        ? user['phone'] 
        : '${name.toString().split(' ').first.toLowerCase()}@email.com';
    
    final statusText = user['current_status'];
    final statusColor = user['status_color'] ?? Colors.transparent;
    final subTime = user['status_sub'] ?? 'Sin reservas hoy';
    final bool isCancelled = statusText == 'CANCELADO';
    final role = user['role'] ?? 'client';
    final isAdmin = role == 'admin';

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Opacity(
        opacity: isCancelled ? 0.6 : 1.0,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isCancelled ? slate500 : primaryColor.withValues(alpha: 0.2), width: 2),
                color: primaryColor.withValues(alpha: 0.2),
                image: avatarUrl != null && avatarUrl.toString().isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(avatarUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: (avatarUrl == null || avatarUrl.toString().isEmpty)
                  ? Center(
                      child: Text(
                        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isAdmin) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: primaryColor),
                          ),
                          child: Text(
                            'ADMIN',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: TextStyle(color: slate500, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (statusText != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusBadge(
                    text: statusText,
                    color: statusColor,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subTime,
                    style: TextStyle(
                      color: slate500,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: slate400, size: 20),
              color: backgroundDark,
              onSelected: (value) {
                if (value == 'toggle_admin') {
                  _toggleUserRole(user['id'], isAdmin ? 'client' : 'admin');
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'toggle_admin',
                  child: Text(
                    isAdmin ? 'Quitar rol Admin' : 'Hacer Administrador',
                    style: TextStyle(
                      color: isAdmin ? rose500 : emerald500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

    );
  }
}
