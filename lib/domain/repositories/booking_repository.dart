import 'package:mi_gym_flutter/domain/entities/booking_entity.dart';

abstract class BookingRepository {
  Future<void> createBooking(String scheduleId, String userId);
  Future<void> cancelBooking(String scheduleId, String userId);
  Future<List<BookingEntity>> getBookings(String userId, {required bool upcoming});
}
