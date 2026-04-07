import 'package:flutter/material.dart';
import 'package:mi_gym_flutter/models/class_model.dart';
import 'package:mi_gym_flutter/models/instructor_model.dart';
import 'package:mi_gym_flutter/services/supabase_service.dart';
import 'package:mi_gym_flutter/theme/app_colors.dart';
import 'package:intl/intl.dart';

class CreateSchedulePage extends StatefulWidget {
  final DateTime initialDate;

  const CreateSchedulePage({super.key, required this.initialDate});

  @override
  State<CreateSchedulePage> createState() => _CreateSchedulePageState();
}

class _CreateSchedulePageState extends State<CreateSchedulePage> {
  bool _isLoading = true;
  bool _isSaving = false;

  List<ClassModel> _classes = [];
  List<InstructorModel> _instructors = [];

  ClassModel? _selectedClass;
  InstructorModel? _selectedInstructor;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  // _capacity has been removed, using _selectedClass.capacity instead

  bool _isRecurring = false;
  final Set<int> _selectedWeekDays = {}; // 1-7 (Mon-Sun)
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));

  final TextEditingController _locationController = TextEditingController(text: 'Main Studio');

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _endDate = _selectedDate.add(const Duration(days: 7)); // Default 1 week finish
    _loadFormData();
  }

  Future<void> _loadFormData() async {
    try {
      final classes = await SupabaseService.getClasses();
      final instructors = await SupabaseService.getInstructors();
      setState(() {
        _classes = classes;
        _instructors = instructors;
        if (_classes.isNotEmpty) {
          _selectedClass = _classes.first;
        }
        if (_instructors.isNotEmpty) _selectedInstructor = _instructors.first;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _saveSchedule() async {
    if (_selectedClass == null || _selectedInstructor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una clase y un instructor'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final startDt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      if (startDt.isBefore(DateTime.now())) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No puedes programar una clase en un horario ya pasado.'), backgroundColor: Colors.redAccent),
          );
        }
        return;
      }

      final extraMins = _selectedClass?.durationMinutes ?? 60;

      if (!_isRecurring) {
        // Single Insert
        final endDt = startDt.add(Duration(minutes: extraMins));
        await SupabaseService.createSchedule(
          classId: _selectedClass!.id,
          instructorId: _selectedInstructor!.id,
          startTime: startDt,
          endTime: endDt,
          capacity: _selectedClass!.capacity,
          locationName: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
        );
      } else {
        // Bulk Insert Logic
        if (_selectedWeekDays.isEmpty) {
          throw 'Debes seleccionar al menos un día de la semana para una clase recurrente';
        }

        final List<Map<String, dynamic>> bulkSchedules = [];
        final int capacity = _selectedClass!.capacity;
        DateTime current = _selectedDate;

        // Iterate from start date to end date
        while (!current.isAfter(_endDate)) {
          if (_selectedWeekDays.contains(current.weekday)) {
            final sessionStart = DateTime(
              current.year, current.month, current.day,
              _startTime.hour, _startTime.minute,
            );
            
            // Skip past slots even in bulk
            if (sessionStart.isBefore(DateTime.now())) {
              current = current.add(const Duration(days: 1));
              continue;
            }

            final sessionEnd = sessionStart.add(Duration(minutes: extraMins));

            bulkSchedules.add({
              'class_id': _selectedClass!.id,
              'instructor_id': _selectedInstructor!.id,
              'start_time': sessionStart.toUtc().toIso8601String(),
              'end_time': sessionEnd.toUtc().toIso8601String(),
              'capacity': capacity,
              'location_name': _locationController.text.trim(),
            });
          }
          current = current.add(const Duration(days: 1));
        }

        if (bulkSchedules.isEmpty) {
          throw 'No se generaron sesiones. Verifica el rango de fechas y días elegidos.';
        }

        await SupabaseService.createSchedulesBulk(bulkSchedules);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    // Ensure initialDate is not before firstDate (today)
    final initialDate = _selectedDate.isBefore(DateTime(now.year, now.month, now.day)) 
        ? now 
        : _selectedDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.backgroundDark,
              surface: AppColors.slate700,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.backgroundDark,
              surface: AppColors.slate700,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Programar Clase', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildRecurrenceToggle(),
                  const SizedBox(height: 16),
                  _buildSectionLabel('Clase Base (Molde)'),
                  const SizedBox(height: 8),
                  _buildDropdown<ClassModel>(
                    value: _selectedClass,
                    items: _classes,
                    itemLabel: (c) => '${c.name} (${c.durationMinutes} min)',
                    onChanged: (v) => setState(() => _selectedClass = v),
                  ),
                  const SizedBox(height: 24),
                  
                  _buildSectionLabel('Instructor'),
                  const SizedBox(height: 8),
                  _buildDropdown<InstructorModel>(
                    value: _selectedInstructor,
                    items: _instructors,
                    itemLabel: (i) => i.name,
                    onChanged: (v) => setState(() => _selectedInstructor = v),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel(_isRecurring ? 'Fecha Inicio' : 'Día'),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: _pickDate,
                              child: _buildPickerField(DateFormat('dd MMM yyyy', 'es').format(_selectedDate), Icons.calendar_today),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel(_isRecurring ? 'Fecha Fin' : 'Hora de Inicio'),
                            const SizedBox(height: 8),
                            if (_isRecurring)
                              InkWell(
                                onTap: _pickEndDate,
                                child: _buildPickerField(DateFormat('dd MMM yyyy', 'es').format(_endDate), Icons.calendar_today),
                              )
                            else
                              InkWell(
                                onTap: _pickTime,
                                child: _buildPickerField(_startTime.format(context), Icons.access_time),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (_isRecurring) ...[
                    _buildDaySelector(),
                    const SizedBox(height: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel('Hora de Inicio'),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickTime,
                          child: _buildPickerField(_startTime.format(context), Icons.access_time),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel('Ubicación (Sala)'),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceDark,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.slate800),
                              ),
                              child: TextField(
                                controller: _locationController,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Ej. Studio A',
                                  hintStyle: TextStyle(color: AppColors.slate400),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveSchedule,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: AppColors.backgroundDark)
                          : const Text(
                              'PROGRAMAR CLASE',
                              style: TextStyle(
                                color: AppColors.backgroundDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Widget _buildRecurrenceToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isRecurring ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isRecurring ? AppColors.primary : AppColors.slate800),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.repeat, color: _isRecurring ? AppColors.primary : AppColors.slate400),
              const SizedBox(width: 12),
              const Text('Es Recurrente', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          Switch(
            value: _isRecurring,
            activeThumbColor: AppColors.primary,
            onChanged: (v) => setState(() => _isRecurring = v),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    final days = [
      {'id': DateTime.monday, 'name': 'L'},
      {'id': DateTime.tuesday, 'name': 'M'},
      {'id': DateTime.wednesday, 'name': 'M'},
      {'id': DateTime.thursday, 'name': 'J'},
      {'id': DateTime.friday, 'name': 'V'},
      {'id': DateTime.saturday, 'name': 'S'},
      {'id': DateTime.sunday, 'name': 'D'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Repetir los días:'),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: days.map((day) {
            final isSelected = _selectedWeekDays.contains(day['id']);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedWeekDays.remove(day['id']);
                  } else {
                    _selectedWeekDays.add(day['id'] as int);
                  }
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surfaceDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.slate800),
                ),
                child: Center(
                  child: Text(
                    day['name'] as String,
                    style: TextStyle(
                      color: isSelected ? AppColors.backgroundDark : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_selectedDate) ? _selectedDate : _endDate,
      firstDate: _selectedDate,
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => _datePickerTheme(child),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Widget _datePickerTheme(Widget? child) {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          onPrimary: AppColors.backgroundDark,
          surface: AppColors.slate700,
          onSurface: Colors.white,
        ),
      ),
      child: child!,
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(color: AppColors.slate400, fontWeight: FontWeight.bold, fontSize: 14),
    );
  }

  Widget _buildPickerField(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate800),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text, style: const TextStyle(color: Colors.white)),
          Icon(icon, color: AppColors.primary, size: 20),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate800),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.slate700,
          icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(itemLabel(item)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
