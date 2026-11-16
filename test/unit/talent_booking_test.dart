import 'package:agora_market_app/domain/entities/talent_booking.dart';
import 'package:agora_market_app/presentation/booking/booking_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mocks/mock_repositories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TalentBooking Entity Unit Tests', () {
    const booking = TalentBooking(
      id: 'test_b_001',
      creatorId: 'user_safeer_001',
      creatorName: 'Safeer Hussain',
      clientName: 'Recruiter Org',
      consultationType: '1:1 Architecture Review',
      bookingDate: '2026-11-20',
      startTime: '10:00',
      durationMinutes: 60,
      ratePerHour: 95.0,
      totalPrice: 99.75,
      status: 'CONFIRMED',
      notes: 'Review frame latency telemetry',
      createdAt: '2026-11-16T12:00:00Z',
    );

    test('Serializes to and from Map accurately', () {
      final map = booking.toMap();
      final restored = TalentBooking.fromMap(map);

      expect(restored.id, booking.id);
      expect(restored.creatorId, booking.creatorId);
      expect(restored.creatorName, booking.creatorName);
      expect(restored.consultationType, booking.consultationType);
      expect(restored.bookingDate, booking.bookingDate);
      expect(restored.startTime, booking.startTime);
      expect(restored.durationMinutes, booking.durationMinutes);
      expect(restored.ratePerHour, booking.ratePerHour);
      expect(restored.totalPrice, booking.totalPrice);
      expect(restored.status, booking.status);
      expect(restored.notes, booking.notes);
    });

    test('Calculates formatted start and end time with AM/PM', () {
      expect(booking.formattedTime, '10:00 AM');
      expect(booking.formattedEndTime, '11:00 AM');

      const eveningBooking = TalentBooking(
        id: 'test_b_002',
        creatorId: 'user_safeer_001',
        creatorName: 'Safeer Hussain',
        clientName: 'Client',
        consultationType: 'Technical Audit',
        bookingDate: '2026-11-20',
        startTime: '14:30',
        durationMinutes: 45,
        ratePerHour: 100.0,
        totalPrice: 75.0,
        status: 'CONFIRMED',
        notes: '',
        createdAt: '2026-11-16T12:00:00Z',
      );

      expect(eveningBooking.formattedTime, '02:30 PM');
      expect(eveningBooking.formattedEndTime, '03:15 PM');
    });

    test('Detects slot overlap and conflict accurately', () {
      // 10:00 - 11:00 booking
      expect(booking.overlaps('10:30', 30), isTrue); // Intersecting
      expect(booking.overlaps('09:30', 45), isTrue); // Overlapping start
      expect(booking.overlaps('10:00', 60), isTrue); // Exact match
      expect(
        booking.overlaps('11:00', 30),
        isFalse,
      ); // Adjacent (ends exactly when other starts)
      expect(
        booking.overlaps('09:00', 60),
        isFalse,
      ); // Adjacent (ends at 10:00)
      expect(booking.overlaps('14:00', 60), isFalse); // Completely different
    });

    test('Cancelled bookings do not cause conflicts', () {
      final cancelled = booking.copyWith(status: 'CANCELLED');
      expect(cancelled.overlaps('10:00', 60), isFalse);
    });
  });

  group('BookingProvider State & Workflow Tests', () {
    late MockBookingRepository mockRepo;
    late MockChatRepository mockChatRepo;
    late BookingProvider provider;

    setUp(() {
      mockRepo = MockBookingRepository();
      mockChatRepo = MockChatRepository();
      provider = BookingProvider(
        repository: mockRepo,
        chatRepository: mockChatRepo,
      );
    });

    test('Initializes creator and loads schedule', () async {
      provider.initialize(
        creatorId: 'user_safeer_001',
        creatorName: 'Safeer Hussain',
        hourlyRate: 95.0,
      );

      expect(provider.creatorId, 'user_safeer_001');
      expect(provider.creatorName, 'Safeer Hussain');
      expect(provider.hourlyRate, 95.0);

      await provider.loadBookings();
      expect(provider.creatorBookings.isNotEmpty, isTrue);
    });

    test('Calculates duration pricing and platform escrow fee', () {
      provider.initialize(
        creatorId: 'user_safeer_001',
        creatorName: 'Safeer Hussain',
        hourlyRate: 100.0,
      );

      provider.selectDuration(60);
      expect(provider.calculatedSubtotal, 100.0);
      expect(provider.platformEscrowFee, 5.0);
      expect(provider.totalEstimatedPrice, 105.0);

      provider.selectDuration(30);
      expect(provider.calculatedSubtotal, 50.0);
      expect(provider.platformEscrowFee, 2.5);
      expect(provider.totalEstimatedPrice, 52.5);
    });

    test(
      'Detects conflict on booked slot and rejects duplicate booking',
      () async {
        provider.initialize(
          creatorId: 'user_safeer_001',
          creatorName: 'Safeer Hussain',
          hourlyRate: 95.0,
        );
        await provider.loadBookings();

        final tomorrow = DateTime.now().add(const Duration(days: 1));
        provider.selectDate(tomorrow);
        provider.selectTimeSlot('10:00'); // Seed booking is at 10:00 for 60m

        expect(provider.isSlotConflict('10:00'), isTrue);

        final booking = await provider.confirmBooking();
        expect(booking, isNull);
        expect(
          provider.errorMessage,
          contains('conflicts with an existing appointment'),
        );
      },
    );

    test(
      'Confirms new appointment on open slot and adds to schedule',
      () async {
        provider.initialize(
          creatorId: 'user_safeer_001',
          creatorName: 'Safeer Hussain',
          hourlyRate: 95.0,
        );
        await provider.loadBookings();

        final tomorrow = DateTime.now().add(const Duration(days: 1));
        provider.selectDate(tomorrow);
        provider.selectTimeSlot('14:00'); // 14:00 is free tomorrow
        provider.selectDuration(60);
        provider.selectConsultationType('1:1 Architecture Review');

        expect(provider.isSlotConflict('14:00'), isFalse);

        final booking = await provider.confirmBooking();
        expect(booking, isNotNull);
        expect(booking!.startTime, '14:00');
        expect(booking.status, 'CONFIRMED');

        // Verify slot is now marked conflicting
        expect(provider.isSlotConflict('14:00'), isTrue);
      },
    );

    test('Cancels booking and marks status CANCELLED', () async {
      provider.initialize(
        creatorId: 'user_safeer_001',
        creatorName: 'Safeer Hussain',
        hourlyRate: 95.0,
      );
      await provider.loadBookings();

      final seedBooking = provider.creatorBookings.first;
      final cancelResult = await provider.cancelBooking(seedBooking.id);
      expect(cancelResult, isTrue);

      final updated = provider.creatorBookings.firstWhere(
        (b) => b.id == seedBooking.id,
      );
      expect(updated.status, 'CANCELLED');
    });
  });
}
