import 'package:mi_gym_flutter/domain/entities/gym_class_entity.dart';
import 'package:mi_gym_flutter/domain/entities/instructor_entity.dart';

class ScheduleEntity {
  final String id;
  final String classId;
  final String instructorId;
  final DateTime startTime;
  final DateTime endTime;
  final int capacity;
  final String locationName;
  final bool isLive;

  // Optional: The populated entities for presentation
  final GymClassEntity? gymClass;
  final InstructorEntity? instructor;

  final int bookedCount;
  final bool isUserBooked;

  ScheduleEntity({
    required this.id,
    required this.classId,
    required this.instructorId,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    required this.locationName,
    required this.isLive,
    this.bookedCount = 0,
    this.isUserBooked = false,
    this.gymClass,
    this.instructor,
  });
}
