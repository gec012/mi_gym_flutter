import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mi_gym_flutter/domain/entities/gym_class_entity.dart';
import 'package:mi_gym_flutter/domain/entities/category_entity.dart';
import 'package:mi_gym_flutter/domain/entities/schedule_entity.dart';
import 'package:mi_gym_flutter/domain/entities/instructor_entity.dart';
import 'package:mi_gym_flutter/domain/repositories/class_repository.dart';

class ClassRepositoryImpl implements ClassRepository {
  final SupabaseClient _client;

  ClassRepositoryImpl(this._client);

  @override
  Future<List<CategoryEntity>> getCategories() async {
    final data = await _client.from('categories').select();
    return (data as List).map((json) => CategoryEntity(
      id: json['id'],
      name: json['name'],
      iconUrl: json['icon_url'],
    )).toList();
  }

  @override
  Future<List<GymClassEntity>> getClasses() async {
    final data = await _client.from('classes').select('*, categories(*)');
    return (data as List).map((json) => _mapToGymClass(json)).toList();
  }

  @override
  Future<List<ScheduleEntity>> getSchedules({bool onlyLive = false}) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final dynamic query;

    if (onlyLive) {
      query = _client
          .from('class_schedules')
          .select('*, classes(*, categories(*)), instructors(*), bookings(*)')
          .lte('start_time', now)
          .gte('end_time', now);
    } else {
      query = _client
          .from('class_schedules')
          .select('*, classes(*, categories(*)), instructors(*), bookings(*)')
          .gte('start_time', now)
          .order('start_time', ascending: true);
    }

    final data = await query;
    return (data as List).map((json) => _mapToSchedule(json)).toList();
  }

  @override
  Future<List<InstructorEntity>> getInstructors() async {
    final data = await _client.from('instructors').select().order('name', ascending: true);
    return (data as List).map((json) => InstructorEntity(
      id: json['id'],
      name: json['name'],
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      rating: (json['rating'] ?? 5.0).toDouble(),
    )).toList();
  }

  @override
  Future<GymClassEntity?> getClassById(String id) async {
    final data = await _client.from('classes').select('*, categories(*)').eq('id', id).maybeSingle();
    if (data == null) return null;
    return _mapToGymClass(data);
  }

  @override
  Future<ScheduleEntity?> getScheduleById(String id) async {
    final data = await _client
        .from('class_schedules')
        .select('*, classes(*, categories(*)), instructors(*), bookings(*)')
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return _mapToSchedule(data);
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

  ScheduleEntity _mapToSchedule(Map<String, dynamic> json) {
    var count = 0;
    var booked = false;
    final currentUserId = _client.auth.currentUser?.id;

    if (json['bookings'] != null) {
      final bs = json['bookings'] as List;
      count = bs.where((b) => b['status'] == 'confirmed').length;
      if (currentUserId != null) {
        booked = bs.any(
          (b) => b['user_id'] == currentUserId && b['status'] == 'confirmed',
        );
      }
    }

    return ScheduleEntity(
      id: json['id'],
      classId: json['class_id'],
      instructorId: json['instructor_id'],
      startTime: DateTime.parse(json['start_time']).toLocal(),
      endTime: DateTime.parse(json['end_time']).toLocal(),
      capacity: json['capacity'],
      locationName: json['location_name'] ?? '',
      isLive: json['is_live'] ?? false,
      bookedCount: count,
      isUserBooked: booked,
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
}
