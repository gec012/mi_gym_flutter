import 'package:mi_gym_flutter/models/schedule_model.dart';

class BookingModel {
  final String id;
  final String userId;
  final String scheduleId;
  final String status;
  final bool isPresent;
  final DateTime createdAt;
  
  // Relación con el schedule completo
  final ScheduleModel? schedule;

  BookingModel({
    required this.id,
    required this.userId,
    required this.scheduleId,
    required this.status,
    this.isPresent = false,
    required this.createdAt,
    this.schedule,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    ScheduleModel? scheduleData;
    
    // Si la consulta trae los datos anidados del join
    if (json['class_schedules'] != null) {
      final scheduleJson = json['class_schedules'] as Map<String, dynamic>;
      
      // Armamos un sub-map con los objetos relacionados si vienen desde bookings
      // (ya que bookings -> class_schedules -> classes -> categories, etc.)
      scheduleJson['classes'] = scheduleJson['classes'];
      scheduleJson['instructors'] = scheduleJson['instructors'];
      
      scheduleData = ScheduleModel.fromJson(scheduleJson);
    }

    return BookingModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      scheduleId: json['schedule_id'] as String,
      status: json['status'] as String? ?? 'confirmed',
      isPresent: json['is_present'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      schedule: scheduleData,
    );
  }
}
