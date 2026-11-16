import '../entities/talent_booking.dart';

abstract class BookingRepository {
  Future<List<TalentBooking>> getBookingsForCreator(String creatorId);
  Future<List<TalentBooking>> getBookingsForDate(
    String creatorId,
    String bookingDate,
  );
  Future<bool> createBooking(TalentBooking booking);
  Future<bool> cancelBooking(String bookingId);
  Future<bool> hasConflict({
    required String creatorId,
    required String bookingDate,
    required String startTime,
    required int durationMinutes,
    String? excludeBookingId,
  });
}
