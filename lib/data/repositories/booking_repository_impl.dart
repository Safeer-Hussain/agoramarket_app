import '../../core/database/app_database.dart';
import '../../domain/entities/talent_booking.dart';
import '../../domain/repositories/booking_repository.dart';

class BookingRepositoryImpl implements BookingRepository {
  final AppDatabase database;

  BookingRepositoryImpl({required this.database});

  @override
  Future<List<TalentBooking>> getBookingsForCreator(String creatorId) async {
    return await database.getBookingsForCreator(creatorId);
  }

  @override
  Future<List<TalentBooking>> getBookingsForDate(
    String creatorId,
    String bookingDate,
  ) async {
    return await database.getBookingsForDate(creatorId, bookingDate);
  }

  @override
  Future<bool> createBooking(TalentBooking booking) async {
    final result = await database.insertBooking(booking);
    return result > 0;
  }

  @override
  Future<bool> cancelBooking(String bookingId) async {
    final result = await database.updateBookingStatus(bookingId, 'CANCELLED');
    return result > 0;
  }

  @override
  Future<bool> hasConflict({
    required String creatorId,
    required String bookingDate,
    required String startTime,
    required int durationMinutes,
    String? excludeBookingId,
  }) async {
    return await database.hasBookingConflict(
      creatorId: creatorId,
      bookingDate: bookingDate,
      startTime: startTime,
      durationMinutes: durationMinutes,
      excludeBookingId: excludeBookingId,
    );
  }
}
