import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mi_gym_flutter/domain/entities/booking_entity.dart';
import 'package:mi_gym_flutter/domain/entities/schedule_entity.dart';
import 'package:mi_gym_flutter/domain/entities/gym_class_entity.dart';
import 'package:mi_gym_flutter/domain/entities/instructor_entity.dart';
import 'package:mi_gym_flutter/domain/repositories/booking_repository.dart';

class BookingRepositoryImpl implements BookingRepository {
  final SupabaseClient _client;

  BookingRepositoryImpl(this._client);

  @override
  Future<void> createBooking(String scheduleId, String userId) async {
    await _client.from('bookings').insert({
      'user_id': userId,
      'schedule_id': scheduleId,
      'status': 'confirmed',
    });
  }

  @override
  Future<void> cancelBooking(String scheduleId, String userId) async {
    await _client
        .from('bookings')
        .delete()
        .eq('user_id', userId)
        .eq('schedule_id', scheduleId);
  }

  @override
  Future<List<BookingEntity>> getBookings(String userId, {required bool upcoming}) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final query = _client
        .from('bookings')
        .select('*, class_schedules(*, classes(*, categories(*)), instructors(*))')
        .eq('user_id', userId);

    final data = upcoming 
      ? await query.gte('class_schedules.start_time', now).order('created_at', ascending: false)
      : await query.lt('class_schedules.start_time', now).order('created_at', ascending: false);
    
    return (data as List)
        .where((json) => json['class_schedules'] != null)
        .map((json) => _mapToBooking(json))
        .toList();
  }

  BookingEntity _mapToBooking(Map<String, dynamic> json) {
    return BookingEntity(
      id: json['id'],
      userId: json['user_id'],
      scheduleId: json['schedule_id'],
      status: json['status'] ?? 'confirmed',
      isPresent: json['is_present'] ?? false,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      schedule: json['class_schedules'] != null 
          ? _mapToSchedule(json['class_schedules']) 
          : null,
    );
  }

  ScheduleEntity _mapToSchedule(Map<String, dynamic> json) {
    return ScheduleEntity(
      id: json['id'],
      classId: json['class_id'],
      instructorId: json['instructor_id'],
      startTime: DateTime.parse(json['start_time']).toLocal(),
      endTime: DateTime.parse(json['end_time']).toLocal(),
      capacity: json['capacity'],
      locationName: json['location_name'] ?? '',
      isLive: json['is_live'] ?? false,
      bookedCount: 0, // No necesitamos el count aquí para mis reservas
      isUserBooked: true, // Si está en bookings del usuario, está reservado
      gymClass: json['classes'] != null ? _mapToGymClass(json['classes']) : null,
      instructor: json['instructors'] != null ? InstructorEntity(
        id: json['instructors']['id'],
        name: json['instructors']['name'],
        avatarUrl: json['instructors']['avatar_url'],
        bio: json['instructors']['bio'],
        rating: (json['instructors']['rating'] ?? 5.0).toDouble(),
      ) : null,
    );
  }

  GymClassEntity _mapToGymClass(Map<String, dynamic> json) {
    return GymClassEntity(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      categoryId: json['category_id'] ?? '',
      intensity: _mapIntensity(json['intensity']),
      durationMinutes: json['duration_minutes'] ?? 0,
      basePrice: (json['base_price'] ?? 0.0).toDouble(),
    );
  }

  ClassIntensity _mapIntensity(String? intensity) {
    switch (intensity?.toLowerCase()) {
      case 'low': return ClassIntensity.low;
      case 'high': return ClassIntensity.high;
      case 'medium': 
      default: return ClassIntensity.medium;
    }
  }
}
