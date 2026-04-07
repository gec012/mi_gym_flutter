import 'package:mi_gym_flutter/domain/entities/schedule_entity.dart';

class BookingEntity {
  final String id;
  final String userId;
  final String scheduleId;
  final String status; // 'confirmed', 'waitlist', 'cancelled'
  final bool isPresent;
  final DateTime createdAt;
  final ScheduleEntity? schedule;

  BookingEntity({
    required this.id,
    required this.userId,
    required this.scheduleId,
    required this.status,
    required this.isPresent,
    required this.createdAt,
    this.schedule,
  });
}
