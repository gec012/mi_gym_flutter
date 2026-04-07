import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mi_gym_flutter/models/class_model.dart';
import 'package:mi_gym_flutter/models/category_model.dart';
import 'package:mi_gym_flutter/models/instructor_model.dart';
import 'package:mi_gym_flutter/models/schedule_model.dart';
import 'package:mi_gym_flutter/models/booking_model.dart';

class SupabaseService {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://obbvowajkzpepahmzebb.supabase.co',
      anonKey: 'sb_publishable_NRIZEz-E0OUIDDCAwZJc8A_F6V0F3vD',
    );
  }

  static final SupabaseClient _client = Supabase.instance.client;
  static SupabaseClient get client => _client;

  // --- Authentication ---

  static User? get currentUser => _client.auth.currentUser;

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // --- Profiles ---

  /// Obtiene el perfil del usuario desde la tabla 'profiles'.
  /// Usado tanto para login (verificar rol) como para mostrar datos.
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    return await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
  }

  // --- Instructors ---

  static Future<List<InstructorModel>> getInstructors() async {
    final data = await _client.from('instructors').select();
    return (data as List).map((json) => InstructorModel.fromJson(json)).toList();
  }

  // --- Categories ---

  static Future<List<CategoryModel>> getCategories() async {
    final data = await _client.from('categories').select();
    return (data as List).map((json) => CategoryModel.fromJson(json)).toList();
  }

  // --- Classes ---

  static Future<List<ClassModel>> getClasses() async {
    final data = await _client.from('classes').select('*, categories(*)');
    return (data as List).map((json) => ClassModel.fromJson(json)).toList();
  }

  // --- Schedules ---

  static Future<List<ScheduleModel>> getSchedules() async {
    final now = DateTime.now().toUtc().toIso8601String();
    final data = await _client
        .from('class_schedules')
        .select('*, classes(*, categories(*)), instructors(*), bookings(*)')
        .gte('start_time', now)
        .order('start_time', ascending: true);
    return (data as List).map((json) => ScheduleModel.fromJson(json)).toList();
  }

  static Future<List<ScheduleModel>> getLiveSchedules() async {
    final now = DateTime.now().toUtc().toIso8601String();
    final data = await _client
        .from('class_schedules')
        .select('*, classes(*, categories(*)), instructors(*), bookings(*)')
        .lte('start_time', now)
        .gte('end_time', now);
    return (data as List).map((json) => ScheduleModel.fromJson(json)).toList();
  }

  static Future<List<ScheduleModel>> getSchedulesByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day).toUtc().toIso8601String();
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toUtc().toIso8601String();
    final data = await _client
        .from('class_schedules')
        .select('*, classes(*, categories(*)), instructors(*), bookings(*)')
        .gte('start_time', startOfDay)
        .lte('start_time', endOfDay)
        .order('start_time', ascending: true);
    return (data as List).map((json) => ScheduleModel.fromJson(json)).toList();
  }

  // --- Aggregated Data ---

  static Future<Map<String, dynamic>> getHomeData() async {
    final userId = currentUser?.id;

    final profileFuture = userId != null
        ? getUserProfile(userId)
        : Future.value(null);
    final categoriesFuture = getCategories();
    final classesFuture = getClasses();
    final schedulesFuture = getSchedules();
    final userBookingsFuture = userId != null 
        ? getAllUserBookings() 
        : Future.value(<BookingModel>[]);

    final responses = await Future.wait<dynamic>([
      profileFuture,
      categoriesFuture,
      classesFuture,
      schedulesFuture,
      userBookingsFuture,
    ]);

    return {
      'profile': responses[0],
      'categories': responses[1] as List<CategoryModel>,
      'classes': responses[2] as List<ClassModel>,
      'schedules': responses[3] as List<ScheduleModel>,
      'userBookings': responses[4] as List<BookingModel>,
    };
  }

  static Future<Map<String, dynamic>> getAdminDashboardData() async {
    final liveSessionsFuture = getLiveSchedules();
    final allSchedulesFuture = getSchedules();
    final categoriesFuture = getCategories();
    final classesFuture = getClasses();

    final responses = await Future.wait<dynamic>([
      liveSessionsFuture,
      allSchedulesFuture,
      categoriesFuture,
      classesFuture,
    ]);

    return {
      'schedules_count': (responses[1] as List).length,
      'live_sessions': responses[0] as List<ScheduleModel>,
      'upcoming_schedules': responses[1] as List<ScheduleModel>,
      'categories': responses[2] as List<CategoryModel>,
      'classes': responses[3] as List<ClassModel>,
    };
  }

  // --- Instructors ---

  static Future<List<InstructorModel>> getInstructors() async {
    final data = await _client
        .from('instructors')
        .select()
        .order('name', ascending: true);
    return (data as List)
        .map((json) => InstructorModel.fromJson(json))
        .toList();
  }

  // --- Class CRUD ---

  static Future<ClassModel?> getClassById(String classId) async {
    final data = await _client
        .from('classes')
        .select('*, categories(*)')
        .eq('id', classId)
        .maybeSingle();
    if (data == null) return null;
    return ClassModel.fromJson(data);
  }

  static Future<ClassModel> createClass({
    required String name,
    String? description,
    String? imageUrl,
    String? categoryId,
    String intensity = 'Medium',
    required int durationMinutes,
    double basePrice = 0.00,
  }) async {
    final data = await _client
        .from('classes')
        .insert({
          'name': name,
          'description': description,
          'image_url': imageUrl,
          'category_id': categoryId,
          'intensity': intensity,
          'duration_minutes': durationMinutes,
          'base_price': basePrice,
        })
        .select()
        .single();
    return ClassModel.fromJson(data);
  }

  static Future<void> updateClass({
    required String classId,
    required String name,
    String? description,
    String? imageUrl,
    String? categoryId,
    String intensity = 'Medium',
    required int durationMinutes,
    double basePrice = 0.00,
  }) async {
    await _client
        .from('classes')
        .update({
          'name': name,
          'description': description,
          'image_url': imageUrl,
          'category_id': categoryId,
          'intensity': intensity,
          'duration_minutes': durationMinutes,
          'base_price': basePrice,
        })
        .eq('id', classId);
  }

  static Future<void> deleteClass(String classId) async {
    await _client.from('classes').delete().eq('id', classId);
  }

  // --- Schedule CRUD ---

  static Future<ScheduleModel> createSchedule({
    required String classId,
    required String instructorId,
    required DateTime startTime,
    required DateTime endTime,
    required int capacity,
    String? locationName,
  }) async {
    final data = await _client
        .from('class_schedules')
        .insert({
          'class_id': classId,
          'instructor_id': instructorId,
          'start_time': startTime.toUtc().toIso8601String(),
          'end_time': endTime.toUtc().toIso8601String(),
          'capacity': capacity,
          'location_name': locationName,
        })
        .select()
        .single();
    return ScheduleModel.fromJson(data);
  }

  static Future<void> deleteSchedule(String scheduleId) async {
    await _client.from('class_schedules').delete().eq('id', scheduleId);
  }

  // --- Booking CRUD ---

  static Future<void> bookClass(String scheduleId) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado.');

    // Validar concurrencia leyendo los cupos antes de la inserción.
    final scheduleData = await _client
        .from('class_schedules')
        .select('capacity')
        .eq('id', scheduleId)
        .single();
    final capacity = scheduleData['capacity'] as int;

    final bookingsList = await _client
        .from('bookings')
        .select('id')
        .eq('schedule_id', scheduleId)
        .eq('status', 'confirmed');
    final currentBookings = (bookingsList as List).length;

    if (currentBookings >= capacity) {
      throw Exception(
        'Lo sentimos, la clase ya no tiene cupos disponibles.',
      );
    }

    try {
      // Inserción de la reserva
      await _client.from('bookings').insert({
        'user_id': userId,
        'schedule_id': scheduleId,
        'status': 'confirmed',
      });

      // Control de Concurrencia Optimista (Verificación post-inserción)
      final verifyBookingsList = await _client
          .from('bookings')
          .select('id, user_id, created_at')
          .eq('schedule_id', scheduleId)
          .eq('status', 'confirmed')
          .order('created_at', ascending: true);

      final listBookings = verifyBookingsList as List;
      if (listBookings.length > capacity) {
        // Encontrar si la reserva actual es la que sobrepasó la capacidad
        final overflowBookings = listBookings.sublist(capacity);
        final isMyBookingOverflow = overflowBookings.any((b) => b['user_id'] == userId);

        if (isMyBookingOverflow) {
          // Revertir la reserva excedente
          await _client
              .from('bookings')
              .delete()
              .eq('user_id', userId)
              .eq('schedule_id', scheduleId);
          throw Exception('Lo sentimos, otro usuario acaba de tomar el último cupo en este instante.');
        }
      }
    } catch (e) {
      if (e.toString().contains('último cupo') || e.toString().contains('cupos disponibles')) {
        rethrow;
      }
      throw Exception(
        'Error al intentar agendar o ya tienes una reserva activa.',
      );
    }
  }

  static Future<void> cancelBooking(String scheduleId) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado.');

    await _client
        .from('bookings')
        .delete()
        .eq('user_id', userId)
        .eq('schedule_id', scheduleId);
  }

  static Future<List<BookingModel>> getAllUserBookings() async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('bookings')
        .select('*, class_schedules(*, classes(*, categories(*)), instructors(*))')
        .eq('user_id', userId)
        .eq('status', 'confirmed');

    return (data as List)
        .where((json) => json['class_schedules'] != null)
        .map((json) => BookingModel.fromJson(json))
        .toList();
  }

  static Future<List<BookingModel>> getUserBookings({required bool upcoming}) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado.');

    final now = DateTime.now().toUtc().toIso8601String();

    final query = _client
        .from('bookings')
        .select('*, class_schedules(*, classes(*, categories(*)), instructors(*))')
        .eq('user_id', userId);

    final data = upcoming 
      ? await query.gte('class_schedules.start_time', now).order('created_at', ascending: false)
      : await query.lt('class_schedules.start_time', now).order('created_at', ascending: false);
    
    // Filtro en memoria por limitación de filtro en inner join si class_schedules es null
    final List<BookingModel> bookings = (data as List)
        .where((json) => json['class_schedules'] != null) // Filtramos aquellos donde el join fue exitoso tras el condicional
        .map((json) => BookingModel.fromJson(json))
        .toList();
        
    // Ordenamiento final en memoria por start_time, ascendente para próximos, descendente para pasado
    bookings.sort((a, b) {
      if (a.schedule == null || b.schedule == null) return 0;
      return upcoming 
          ? a.schedule!.startTime.compareTo(b.schedule!.startTime)
          : b.schedule!.startTime.compareTo(a.schedule!.startTime);
    });

    return bookings;
  }

  // --- Storage ---

  /// Uploads an image to Supabase Storage and returns the public URL.
  static Future<String> uploadClassImage({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    final path = 'classes/$fileName';

    await _client.storage
        .from('class-images')
        .uploadBinary(
          path,
          imageBytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );

    final publicUrl = _client.storage.from('class-images').getPublicUrl(path);
    return publicUrl;
  }

  /// Sube una imagen de perfil a 'profiles' bucket y devuelve la URL.
  static Future<String> uploadProfileImage({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('No autenticado');
    
    // Guardamos en una subcarpeta con el ID del usuario para evitar colisiones
    final path = '$userId/$fileName';

    await _client.storage
        .from('profiles')
        .uploadBinary(
          path,
          imageBytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );

    return _client.storage.from('profiles').getPublicUrl(path);
  }

  /// Actualiza datos parciales del perfil del usuario (como avatar_url).
  static Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('No autenticado');

    await _client
        .from('profiles')
        .update(updates)
        .eq('id', userId);
  }

  /// Cambia la contraseña del usuario autenticado actual.
  static Future<void> changePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }
}
