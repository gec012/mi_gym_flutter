import 'package:mi_gym_flutter/models/class_model.dart';
import 'package:mi_gym_flutter/models/instructor_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScheduleModel {
  final String id;
  final String classId;
  final String instructorId;
  final DateTime startTime;
  final DateTime endTime;
  final int capacity;
  final String? locationName;
  final bool isLive;

  int bookedCount;
  bool isUserBooked;

  final ClassModel? classData;
  final InstructorModel? instructor;

  ScheduleModel({
    required this.id,
    required this.classId,
    required this.instructorId,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    this.locationName,
    this.isLive = false,
    this.bookedCount = 0,
    this.isUserBooked = false,
    this.classData,
    this.instructor,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    int count = 0;
    bool booked = false;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    if (json['bookings'] != null) {
      final bs = json['bookings'] as List;
      count = bs.where((b) => b['status'] == 'confirmed').length;
      if (currentUserId != null) {
        booked = bs.any(
          (b) => b['user_id'] == currentUserId && b['status'] == 'confirmed',
        );
      }
    }

    return ScheduleModel(
      id: json['id'] as String,
      classId: json['class_id'] as String,
      instructorId: json['instructor_id'] as String,
      // Convertimos la hora UTC (que viene de la BD) a la hora local del dispositivo del usuario
      startTime: DateTime.parse(json['start_time']).toLocal(),
      endTime: DateTime.parse(json['end_time']).toLocal(),
      capacity: json['capacity'] as int,
      locationName: json['location_name'] as String?,
      isLive: json['is_live'] as bool? ?? false,
      bookedCount: count,
      isUserBooked: booked,
      classData: json['classes'] != null
          ? ClassModel.fromJson(json['classes'])
          : null,
      instructor: json['instructors'] != null
          ? InstructorModel.fromJson(json['instructors'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class_id': classId,
      'instructor_id': instructorId,
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'capacity': capacity,
      'location_name': locationName,
      'is_live': isLive,
    };
  }
}
