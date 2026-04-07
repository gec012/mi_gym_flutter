import 'package:flutter/material.dart';
import 'package:mi_gym_flutter/models/schedule_model.dart';
import 'package:mi_gym_flutter/services/supabase_service.dart';
import 'package:mi_gym_flutter/theme/app_colors.dart';
import 'package:mi_gym_flutter/widgets/shared/glass_card.dart';
import 'package:mi_gym_flutter/widgets/shared/status_badge.dart';
import 'package:intl/intl.dart';
import 'create_schedule_page.dart';

class AdminCalendarPage extends StatefulWidget {
  const AdminCalendarPage({super.key});

  @override
  State<AdminCalendarPage> createState() => _AdminCalendarPageState();
}

class _AdminCalendarPageState extends State<AdminCalendarPage> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  List<ScheduleModel> _schedules = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final schedules = await SupabaseService.getSchedulesByDate(_selectedDate);
      setState(() {
        _schedules = schedules;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _changeDate(int offset) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: offset));
    });
    _loadData();
  }

  void _scheduleClass() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateSchedulePage(initialDate: _selectedDate)),
    );
    if (result == true) {
      _loadData();
    }
  }

  void _deleteSchedule(ScheduleModel sched) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Eliminar Horario', style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Estás seguro de eliminar ${sched.classData?.name ?? 'Clase'} del día ${DateFormat('dd MMM HH:mm').format(sched.startTime)}?',
          style: TextStyle(color: AppColors.slate400),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: TextStyle(color: AppColors.slate400)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await SupabaseService.deleteSchedule(sched.id);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Horario eliminado'), backgroundColor: Colors.orange),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Calendario', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _schedules.isEmpty
                    ? Center(
                        child: Text(
                          'No hay clases programadas para este día',
                          style: TextStyle(color: AppColors.slate400),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: _schedules.length,
                        itemBuilder: (context, index) {
                          final sched = _schedules[index];
                          return _buildScheduleCard(sched);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scheduleClass,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: AppColors.backgroundDark),
        label: const Text('Agendar Clase', style: TextStyle(color: AppColors.backgroundDark, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(bottom: BorderSide(color: AppColors.slate800)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: AppColors.primary),
            onPressed: () => _changeDate(-1),
          ),
          Column(
            children: [
              Text(
                DateFormat('EEEE', 'es').format(_selectedDate).toUpperCase(),
                style: TextStyle(color: AppColors.slate400, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text(
                DateFormat('dd MMM yyyy', 'es').format(_selectedDate),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: AppColors.primary),
            onPressed: () => _changeDate(1),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(ScheduleModel sched) {
    final intensityColor = sched.classData?.intensity == 'High'
        ? const Color(0xFF7C3AED)
        : (sched.classData?.intensity == 'Medium' ? const Color(0xFFF59E0B) : const Color(0xFF22C55E));

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: AppColors.slate800, width: 1)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('HH:mm').format(sched.startTime),
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    DateFormat('HH:mm').format(sched.endTime),
                    style: TextStyle(color: AppColors.slate400, fontSize: 12),
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
                    sched.classData?.name ?? 'Clase desconocida',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person, color: AppColors.slate400, size: 14),
                      const SizedBox(width: 4),
                      Text(sched.instructor?.name ?? 'Sin asignar', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('${sched.bookedCount}/${sched.capacity} cupos', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
                      const Spacer(),
                      if (sched.classData != null)
                        StatusBadge(
                          text: sched.classData!.intensity,
                          color: intensityColor,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _deleteSchedule(sched),
            )
          ],
        ),
      ),
    );
  }
}
