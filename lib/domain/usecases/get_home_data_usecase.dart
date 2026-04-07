import 'package:mi_gym_flutter/domain/entities/user_entity.dart';
import 'package:mi_gym_flutter/domain/entities/category_entity.dart';
import 'package:mi_gym_flutter/domain/entities/gym_class_entity.dart';
import 'package:mi_gym_flutter/domain/entities/schedule_entity.dart';
import 'package:mi_gym_flutter/domain/entities/booking_entity.dart';
import 'package:mi_gym_flutter/domain/repositories/auth_repository.dart';
import 'package:mi_gym_flutter/domain/repositories/class_repository.dart';
import 'package:mi_gym_flutter/domain/repositories/booking_repository.dart';

class HomeData {
  final UserEntity? profile;
  final List<CategoryEntity> categories;
  final List<GymClassEntity> classes;
  final List<ScheduleEntity> schedules;
  final List<BookingEntity> userBookings;

  HomeData({
    required this.profile,
    required this.categories,
    required this.classes,
    required this.schedules,
    required this.userBookings,
  });
}

class GetHomeDataUseCase {
  final AuthRepository _authRepository;
  final ClassRepository _classRepository;
  final BookingRepository _bookingRepository;

  GetHomeDataUseCase(
    this._authRepository,
    this._classRepository,
    this._bookingRepository,
  );

  Future<HomeData> execute() async {
    final user = await _authRepository.getCurrentUser();
    final userId = user?.id;

    final profile = user;
    final categoriesFuture = _classRepository.getCategories();
    final classesFuture = _classRepository.getClasses();
    final schedulesFuture = _classRepository.getSchedules();
    final userBookingsFuture = userId != null 
        ? _bookingRepository.getBookings(userId, upcoming: false) // Quiero todas para el perfil
        : Future.value(<BookingEntity>[]);

    final results = await Future.wait([
      categoriesFuture,
      classesFuture,
      schedulesFuture,
      userBookingsFuture,
    ]);

    return HomeData(
      profile: profile,
      categories: results[0] as List<CategoryEntity>,
      classes: results[1] as List<GymClassEntity>,
      schedules: results[2] as List<ScheduleEntity>,
      userBookings: results[3] as List<BookingEntity>,
    );
  }
}
