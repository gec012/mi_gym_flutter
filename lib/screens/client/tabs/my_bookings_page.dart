import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mi_gym_flutter/domain/entities/booking_entity.dart';
import 'package:mi_gym_flutter/services/supabase_service.dart';
import 'package:mi_gym_flutter/screens/client/class_details_page.dart';
import 'package:mi_gym_flutter/theme/app_colors.dart';
import 'package:mi_gym_flutter/widgets/shared/status_badge.dart';

class MyBookingsPage extends StatefulWidget {
  final List<BookingEntity> bookings;
  final VoidCallback onRefresh;

  const MyBookingsPage({
    super.key,
    required this.bookings,
    required this.onRefresh,
  });

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  bool _isUpcoming = true;

  Future<void> _cancelBooking(BookingEntity booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Cancelar Reserva', style: TextStyle(color: Colors.white)),
        content: Text('¿Estás seguro de que quieres cancelar ${booking.schedule?.gymClass?.name ?? 'esta clase'}?', style: const TextStyle(color: Colors.white70)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver', style: TextStyle(color: AppColors.slate400)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancelar'),
          ),
        ],
      )
    );

    if (confirm != true) return;

    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await SupabaseService.cancelBooking(booking.scheduleId);
      if (!mounted) return;
      Navigator.pop(context); // close loading
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reserva cancelada.'), backgroundColor: Colors.orange)
      );
      widget.onRefresh();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredBookings = widget.bookings.where((b) {
      if (b.schedule == null) return false;
      final isFuture = b.schedule!.startTime.isAfter(DateTime.now());
      return _isUpcoming ? isFuture : !isFuture;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Column(
        children: [
          _buildTabSwitcher(),
          Expanded(
            child: _buildBookingsList(filteredBookings),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.primary.withValues(alpha: 0.2))),
      ),
      child: Row(
        children: [
          _buildTabButton('PRÓXIMAS', true),
          _buildTabButton('HISTORIAL', false),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, bool isUpcomingTab) {
    final isActive = _isUpcoming == isUpcomingTab;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (!isActive) {
            setState(() {
              _isUpcoming = isUpcomingTab;
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? AppColors.primary : AppColors.slate500,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingsList(List<BookingEntity> bookings) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: AppColors.slate500.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              _isUpcoming ? 'Sin reservas próximas' : 'Sin historial',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _isUpcoming ? 'Reserva una clase en horarios' : 'Tu historial aparecerá aquí',
              style: const TextStyle(color: AppColors.slate400, fontSize: 14),
            )
          ],
        ),
      );
    }

    // Agrupar por fecha
    final Map<String, List<BookingEntity>> groupedBookings = {};
    for (var b in bookings) {
      final date = b.schedule?.startTime ?? DateTime.now();
      final now = DateTime.now();
      String dateKey;
      
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        dateKey = 'Hoy, ${DateFormat('d MMM').format(date)}';
      } else if (date.year == now.year && date.month == now.month && date.day == now.day + 1) {
        dateKey = 'Mañana, ${DateFormat('d MMM').format(date)}';
      } else {
        dateKey = DateFormat('EEEE, d MMM', 'es_ES').format(date);
        // Fallback simple si no hay locales configurados
        if (dateKey.contains('EEEE')) dateKey = DateFormat('EEEE, d MMM').format(date);
      }
      
      if (!groupedBookings.containsKey(dateKey)) {
        groupedBookings[dateKey] = [];
      }
      groupedBookings[dateKey]!.add(b);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      physics: const BouncingScrollPhysics(),
      itemCount: groupedBookings.length,
      itemBuilder: (context, index) {
        final dateKey = groupedBookings.keys.elementAt(index);
        final list = groupedBookings[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16, left: 8),
              child: Text(
                dateKey.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            ...list.map((b) => _buildBookingCard(b)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildBookingCard(BookingEntity booking) {
    final schedule = booking.schedule;
    final cls = schedule?.gymClass;
    if (schedule == null || cls == null) return const SizedBox.shrink();
    
    final isWaitlist = booking.status == 'waitlist';
    final timeStr = DateFormat('HH:mm').format(schedule.startTime);

    return GestureDetector(
      onTap: () {
        // Debemos refactorizar ClassDetailsPage para aceptar entity o id
        // Por ahora navegamos con refresh
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ClassDetailsPage(
              scheduleId: schedule.id,
              onRefresh: widget.onRefresh,
            ),
          )
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.slate800.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            SizedBox(
              height: 140,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(cls.imageUrl, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      )
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: StatusBadge(
                      text: isWaitlist ? 'LISTA ESPERA' : 'CONFIRMADO',
                      color: isWaitlist ? AppColors.warning : AppColors.success,
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          timeStr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cls.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Coach: ${schedule.instructor?.name ?? 'TBA'}',
                    style: const TextStyle(color: AppColors.slate400, fontSize: 13),
                  ),
                  
                  if (_isUpcoming) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => _cancelBooking(booking),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                          foregroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.redAccent, width: 0.5),
                          )
                        ),
                        child: Text(
                          isWaitlist ? 'SALIR DE LISTA' : 'CANCELAR RESERVA',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    )
                  ]
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
