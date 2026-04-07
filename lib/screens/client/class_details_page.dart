import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mi_gym_flutter/domain/entities/schedule_entity.dart';
import 'package:mi_gym_flutter/domain/usecases/get_schedule_usecase.dart';
import 'package:mi_gym_flutter/services/supabase_service.dart';
import 'package:mi_gym_flutter/theme/app_colors.dart';
import 'package:mi_gym_flutter/widgets/shared/status_badge.dart';
import 'package:mi_gym_flutter/presentation/helpers/intensity_helper.dart';

class ClassDetailsPage extends StatefulWidget {
  final String scheduleId;
  final VoidCallback onRefresh;

  const ClassDetailsPage({
    super.key,
    required this.scheduleId,
    required this.onRefresh,
  });

  @override
  State<ClassDetailsPage> createState() => _ClassDetailsPageState();
}

class _ClassDetailsPageState extends State<ClassDetailsPage> {
  ScheduleEntity? _schedule;
  bool _isLoading = true;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchSchedule();
  }

  Future<void> _fetchSchedule() async {
    setState(() => _isLoading = true);
    try {
      final getScheduleUseCase = Provider.of<GetScheduleUseCase>(context, listen: false);
      final schedule = await getScheduleUseCase.execute(widget.scheduleId);
      if (mounted) {
        setState(() {
          _schedule = schedule;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar clase: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleBookingOrCancellation() async {
    if (_schedule == null) return;

    setState(() => _isActionLoading = true);
    try {
      if (_schedule!.isUserBooked) {
        await SupabaseService.cancelBooking(_schedule!.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reserva cancelada.'), backgroundColor: Colors.orange),
        );
      } else {
        await SupabaseService.bookClass(_schedule!.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Reserva confirmada!'), backgroundColor: Colors.green),
        );
      }
      widget.onRefresh();
      _fetchSchedule(); // Refresh local data
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_schedule == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: Text('No se encontró la clase', style: TextStyle(color: Colors.white))),
      );
    }

    final cls = _schedule!.gymClass!;
    final instructor = _schedule!.instructor;
    final isFull = _schedule!.bookedCount >= _schedule!.capacity;
    final isBooked = _schedule!.isUserBooked;
    final spotsLeft = _schedule!.capacity - _schedule!.bookedCount;
    final spotsText = isFull ? 'Lleno' : '$spotsLeft Lugares';

    final dateStr = DateFormat('MMM d - HH:mm', 'es_ES').format(_schedule!.startTime);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero
                SizedBox(
                  height: 400,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(cls.imageUrl, fit: BoxFit.cover),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.backgroundDark.withValues(alpha: 0.4),
                                AppColors.backgroundDark.withValues(alpha: 0.9),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 16,
                        left: 16,
                        child: _buildIconButton(
                          icon: Icons.arrow_back,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ),
                      Positioned(
                        bottom: 24,
                        left: 24,
                        right: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            StatusBadge(
                              text: IntensityHelper.getLabel(cls.intensity),
                              color: IntensityHelper.getColor(cls.intensity),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              cls.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Instructor
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.primary.withValues(alpha: 0.1))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                              image: instructor != null
                                  ? DecorationImage(image: NetworkImage(instructor.avatarUrl), fit: BoxFit.cover)
                                  : const DecorationImage(image: NetworkImage('https://via.placeholder.com/150'), fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                instructor?.name ?? 'Coach',
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const Text('Instructor', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Info
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildInfoBox(Icons.calendar_today, 'FECHA', dateStr),
                      _buildInfoBox(Icons.schedule, 'DURACIÓN', '${cls.durationMinutes}m'),
                      _buildInfoBox(Icons.groups, 'CUPOS', spotsText),
                      _buildInfoBox(Icons.bolt, 'INTENSIDAD', IntensityHelper.getLabel(cls.intensity)),
                    ],
                  ),
                ),

                // About
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sobre la clase',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        cls.description,
                        style: const TextStyle(color: AppColors.slate400, fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark.withValues(alpha: 0.95),
                border: Border(top: BorderSide(color: AppColors.primary.withValues(alpha: 0.1))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Inversión', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
                      Text('\$${cls.basePrice.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  _isActionLoading
                      ? const Padding(padding: EdgeInsets.only(right: 32.0), child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: (isFull && !isBooked) ? null : _handleBookingOrCancellation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isBooked ? Colors.redAccent.withValues(alpha: 0.1) : AppColors.primary,
                            foregroundColor: isBooked ? Colors.redAccent : AppColors.backgroundDark,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            side: isBooked ? const BorderSide(color: Colors.redAccent) : BorderSide.none,
                          ),
                          child: Text(
                            isBooked ? 'Cancelar Reserva' : (isFull ? 'Lleno' : 'Reservar Ahora'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildInfoBox(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(color: AppColors.slate400, fontSize: 10, fontWeight: FontWeight.bold)),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
