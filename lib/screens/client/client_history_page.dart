import 'package:flutter/material.dart';
import 'package:mi_gym_flutter/models/booking_model.dart';
import 'package:mi_gym_flutter/services/supabase_service.dart';
import 'package:mi_gym_flutter/theme/app_colors.dart';
import 'package:mi_gym_flutter/widgets/shared/glass_card.dart';
import 'package:intl/intl.dart';

class ClientHistoryPage extends StatefulWidget {
  const ClientHistoryPage({super.key});

  @override
  State<ClientHistoryPage> createState() => _ClientHistoryPageState();
}

class _ClientHistoryPageState extends State<ClientHistoryPage> {
  bool _isLoading = true;
  List<BookingModel> _pastBookings = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final allBookings = await SupabaseService.getAllUserBookings();
      final now = DateTime.now();
      
      final past = allBookings.where((b) {
        if (b.schedule == null) return false;
        return b.status == 'confirmed' && b.schedule!.endTime.isBefore(now);
      }).toList();

      past.sort((a, b) => b.schedule!.startTime.compareTo(a.schedule!.startTime));

      if (mounted) {
        setState(() {
          _pastBookings = past;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar historial: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Historial de Entrenamiento', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _pastBookings.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _pastBookings.length,
                  itemBuilder: (context, index) {
                    final booking = _pastBookings[index];
                    return _buildHistoryCard(booking);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 64, color: AppColors.slate600),
          const SizedBox(height: 16),
          Text(
            'Aún no tienes historial',
            style: TextStyle(color: AppColors.slate400, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Tus clases completadas aparecerán aquí',
            style: TextStyle(color: AppColors.slate500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BookingModel booking) {
    final sched = booking.schedule!;
    final cls = sched.classData;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              decoration: BoxDecoration(
                color: AppColors.slate800,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('d', 'es').format(sched.startTime),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    DateFormat('MMM', 'es').format(sched.startTime).toUpperCase(),
                    style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
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
                    cls?.name ?? 'Clase eliminada',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('HH:mm').format(sched.startTime)} - ${sched.instructor?.name ?? 'Instructor'}',
                    style: TextStyle(color: AppColors.slate400, fontSize: 14),
                  ),
                ],
              ),
            ),
            if (booking.isPresent == true)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: AppColors.success, size: 16),
              )
          ],
        ),
      ),
    );
  }
}
