import 'package:flutter/material.dart';
import 'package:mi_gym_flutter/domain/entities/category_entity.dart';
import 'package:mi_gym_flutter/domain/entities/schedule_entity.dart';
import 'package:mi_gym_flutter/screens/client/class_details_page.dart';
import 'package:mi_gym_flutter/theme/app_colors.dart';
import 'package:mi_gym_flutter/widgets/shared/status_badge.dart';
import 'package:mi_gym_flutter/presentation/helpers/intensity_helper.dart';

class ClasesPage extends StatefulWidget {
  final List<CategoryEntity> categories;
  final List<ScheduleEntity> schedules;
  final VoidCallback onRefresh;

  const ClasesPage({
    super.key,
    required this.categories,
    required this.schedules,
    required this.onRefresh,
  });

  @override
  State<ClasesPage> createState() => _ClasesPageState();
}

class _ClasesPageState extends State<ClasesPage> {
  String selectedCategory = 'Todas';
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final nextDays = List.generate(14, (index) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day + index);
    });

    final catList = ['Todas', ...widget.categories.map((c) => c.name)];

    var filteredSchedules = widget.schedules.where((s) {
      final sDate = DateTime(
        s.startTime.year,
        s.startTime.month,
        s.startTime.day,
      );
      return sDate.year == selectedDate.year &&
          sDate.month == selectedDate.month &&
          sDate.day == selectedDate.day;
    }).toList();

    if (selectedCategory != 'Todas') {
      final targetCat = widget.categories.firstWhere(
        (c) => c.name == selectedCategory,
        orElse: () => CategoryEntity(id: '', name: ''),
      );
      if (targetCat.id.isNotEmpty) {
        filteredSchedules = filteredSchedules
            .where((s) => s.gymClass?.categoryId == targetCat.id)
            .toList();
      }
    }

    filteredSchedules.sort((a, b) => a.startTime.compareTo(b.startTime));

    int availableTodayCount = filteredSchedules
        .where(
          (s) =>
              s.startTime.isAfter(DateTime.now()) && s.bookedCount < s.capacity,
        )
        .length;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          backgroundColor: AppColors.backgroundDark.withValues(alpha: 0.95),
          pinned: true,
          elevation: 0,
          titleSpacing: 24,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Horarios',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.search, color: AppColors.primary),
                  onPressed: () {},
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: nextDays.length,
                    itemBuilder: (context, index) {
                      final date = nextDays[index];
                      final isSelected = date.year == selectedDate.year &&
                          date.month == selectedDate.month &&
                          date.day == selectedDate.day;
                      final dayName = _getShortDayName(date.weekday);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedDate = date;
                          });
                        },
                        child: Container(
                          width: 60,
                          margin: const EdgeInsets.only(
                            right: 12,
                            bottom: 8,
                            top: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.slate800.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : AppColors.slate400,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${date.day}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      bottom: 12,
                    ),
                    itemCount: catList.length,
                    itemBuilder: (context, index) {
                      final cat = catList[index];
                      final isSelected = selectedCategory == cat;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCategory = cat;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.slate800.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Center(
                            child: Text(
                              cat,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.slate300,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      selectedDate.year == DateTime.now().year &&
                              selectedDate.month == DateTime.now().month &&
                              selectedDate.day == DateTime.now().day
                          ? "Clases de hoy"
                          : "Clases disponibles",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "($availableTodayCount disponibles)",
                      style: TextStyle(fontSize: 14, color: AppColors.slate400),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (filteredSchedules.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'No hay clases disponibles',
                        style: TextStyle(color: AppColors.slate500, fontSize: 16),
                      ),
                    ),
                  )
                else
                  ...filteredSchedules.map(
                    (schedule) => _buildClassCard(schedule, context),
                  ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClassCard(ScheduleEntity schedule, BuildContext context) {
    final cls = schedule.gymClass;
    if (cls == null) return const SizedBox.shrink();

    final isFull = schedule.bookedCount >= schedule.capacity;
    final isBookedByUser = schedule.isUserBooked;
    final timeStr =
        '${schedule.startTime.hour.toString().padLeft(2, '0')}:${schedule.startTime.minute.toString().padLeft(2, '0')}';

    final intensityColor = IntensityHelper.getColor(cls.intensity);
    final intensityLabel = IntensityHelper.getLabel(cls.intensity);

    return GestureDetector(
      onTap: () => _navigateToDetails(schedule),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.slate800,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network(
                  cls.imageUrl,
                  fit: BoxFit.cover,
                  color: Colors.black.withValues(alpha: 0.4),
                  colorBlendMode: BlendMode.darken,
                  errorBuilder: (_, _, _) => const Center(
                    child: Icon(
                      Icons.fitness_center,
                      size: 40,
                      color: Colors.white24,
                    ),
                  ),
                ),
              ),
            ),

            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      AppColors.backgroundDark.withValues(alpha: 0.95),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              top: 16,
              left: 16,
              child: StatusBadge(
                text: intensityLabel,
                color: intensityColor,
              ),
            ),

            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.schedule, color: AppColors.primary, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '$timeStr - ${cls.durationMinutes}m',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cls.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'con ${schedule.instructor?.name ?? 'TBA'}',
                          style: TextStyle(color: AppColors.slate300, fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (isBookedByUser)
                        const Text(
                          'RESERVADO',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        )
                      else if (isFull)
                        const Text(
                          'LLENO',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        )
                      else
                        Row(
                          children: [
                            SizedBox(
                              width: 60,
                              height: 6,
                              child: LinearProgressIndicator(
                                value: schedule.capacity > 0
                                    ? schedule.bookedCount / schedule.capacity
                                    : 0,
                                backgroundColor: AppColors.slate700,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${schedule.bookedCount} / ${schedule.capacity}',
                              style: TextStyle(
                                color: AppColors.slate300,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => _navigateToDetails(schedule),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isBookedByUser
                              ? Colors.transparent
                              : (isFull ? AppColors.slate700 : AppColors.primary),
                          foregroundColor: isBookedByUser
                              ? AppColors.primary
                              : (isFull ? Colors.white : Colors.black),
                          elevation: 0,
                          minimumSize: const Size(90, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: isBookedByUser
                                ? BorderSide(color: AppColors.primary, width: 2)
                                : BorderSide.none,
                          ),
                        ),
                        child: Text(
                          isBookedByUser
                              ? 'VER RES.'
                              : (isFull ? 'VER' : 'VER'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetails(ScheduleEntity schedule) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ClassDetailsPage(scheduleId: schedule.id, onRefresh: widget.onRefresh),
      ),
    );
  }

  String _getShortDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'LUN';
      case DateTime.tuesday:
        return 'MAR';
      case DateTime.wednesday:
        return 'MIÉ';
      case DateTime.thursday:
        return 'JUE';
      case DateTime.friday:
        return 'VIE';
      case DateTime.saturday:
        return 'SÁB';
      case DateTime.sunday:
        return 'DOM';
      default:
        return '';
    }
  }
}
