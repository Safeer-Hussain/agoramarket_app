import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/chat_entities.dart';
import '../../domain/entities/talent_booking.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/repositories/chat_repository.dart';

class ConsultationTypeInfo {
  final String title;
  final String description;

  const ConsultationTypeInfo({required this.title, required this.description});
}

class BookingProvider extends ChangeNotifier {
  final BookingRepository repository;
  final ChatRepository? chatRepository;

  BookingProvider({required this.repository, this.chatRepository});

  static const List<ConsultationTypeInfo> consultationTypes = [
    ConsultationTypeInfo(
      title: '1:1 Architecture Review',
      description:
          'System design, high-throughput scaling and deep-dive code audit',
    ),
    ConsultationTypeInfo(
      title: 'Milestone Technical Audit',
      description:
          'Milestone deliverable review, test coverage & contract verification',
    ),
    ConsultationTypeInfo(
      title: 'Technical Interview Screen',
      description:
          'Senior talent assessment, live coding evaluation and bar check',
    ),
    ConsultationTypeInfo(
      title: 'Emergency Incident Response',
      description:
          'Immediate live debugging, crash root cause triage and mitigation',
    ),
  ];

  static const List<int> durationOptions = [30, 45, 60, 90];

  static const List<String> standardTimeSlots = [
    '09:00',
    '10:00',
    '11:30',
    '14:00',
    '15:30',
    '17:00',
    '18:30',
  ];

  String _creatorId = '';
  String _creatorName = '';
  double _hourlyRate = 95.0;

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTimeSlot = '10:00';
  String _selectedConsultationType = '1:1 Architecture Review';
  int _selectedDurationMinutes = 60;
  String _clientName = 'Marketplace Recruiter';
  String _notes = '';

  List<TalentBooking> _creatorBookings = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  String get creatorId => _creatorId;
  String get creatorName => _creatorName;
  double get hourlyRate => _hourlyRate;
  DateTime get selectedDate => _selectedDate;
  String? get selectedTimeSlot => _selectedTimeSlot;
  String get selectedConsultationType => _selectedConsultationType;
  int get selectedDurationMinutes => _selectedDurationMinutes;
  String get clientName => _clientName;
  String get notes => _notes;
  List<TalentBooking> get creatorBookings => _creatorBookings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get selectedDateString =>
      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

  double get calculatedSubtotal =>
      _hourlyRate * (_selectedDurationMinutes / 60.0);
  double get platformEscrowFee => calculatedSubtotal * 0.05;
  double get totalEstimatedPrice => calculatedSubtotal + platformEscrowFee;

  void initialize({
    required String creatorId,
    required String creatorName,
    required double hourlyRate,
    String? clientName,
  }) {
    _creatorId = creatorId;
    _creatorName = creatorName;
    _hourlyRate = hourlyRate > 0 ? hourlyRate : 95.0;
    if (clientName != null && clientName.isNotEmpty) {
      _clientName = clientName;
    }
    _selectedTimeSlot = '10:00';
    _selectedConsultationType = '1:1 Architecture Review';
    _selectedDurationMinutes = 60;
    _notes = '';
    loadBookings();
  }

  Future<void> loadBookings() async {
    if (_creatorId.isEmpty) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _creatorBookings = await repository.getBookingsForCreator(_creatorId);
    } catch (e) {
      _errorMessage = 'Failed to load creator schedule: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void selectTimeSlot(String slot) {
    _selectedTimeSlot = slot;
    notifyListeners();
  }

  void selectConsultationType(String type) {
    _selectedConsultationType = type;
    notifyListeners();
  }

  void selectDuration(int minutes) {
    _selectedDurationMinutes = minutes;
    notifyListeners();
  }

  void setNotes(String value) {
    _notes = value;
  }

  /// Checks if a given time slot on the selected date conflicts with existing bookings
  bool isSlotConflict(String timeSlot) {
    final dateStr = selectedDateString;
    for (final booking in _creatorBookings) {
      if (booking.bookingDate == dateStr && booking.status != 'CANCELLED') {
        if (booking.overlaps(timeSlot, _selectedDurationMinutes)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Returns whether a given date has at least one active confirmed booking
  bool dateHasBookings(DateTime date) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _creatorBookings.any(
      (b) => b.bookingDate == dateStr && b.status != 'CANCELLED',
    );
  }

  /// Confirms a new appointment booking and inserts to SQLite
  Future<TalentBooking?> confirmBooking() async {
    if (_selectedTimeSlot == null) {
      _errorMessage = 'Please choose an available appointment time slot.';
      notifyListeners();
      return null;
    }

    final hasConflict = isSlotConflict(_selectedTimeSlot!);
    if (hasConflict) {
      _errorMessage =
          'The selected time slot conflicts with an existing appointment.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final booking = TalentBooking(
        id: const Uuid().v4(),
        creatorId: _creatorId,
        creatorName: _creatorName,
        clientName: _clientName,
        consultationType: _selectedConsultationType,
        bookingDate: selectedDateString,
        startTime: _selectedTimeSlot!,
        durationMinutes: _selectedDurationMinutes,
        ratePerHour: _hourlyRate,
        totalPrice: totalEstimatedPrice,
        status: 'CONFIRMED',
        notes: _notes,
        createdAt: DateTime.now().toIso8601String(),
      );

      final success = await repository.createBooking(booking);
      if (!success) {
        _errorMessage = 'Could not persist booking to local database.';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      // If ChatRepository is present, notify the message thread
      if (chatRepository != null) {
        try {
          final conversations = await chatRepository!.getConversations();
          final conv = conversations.firstWhere(
            (c) =>
                c.participantName.toLowerCase() == _creatorName.toLowerCase() ||
                c.id.contains(_creatorId),
            orElse: () => conversations.first,
          );

          final chatMessage = ChatMessage(
            id: const Uuid().v4(),
            conversationId: conv.id,
            senderId: 'client_recruiter',
            senderName: _clientName,
            text:
                'Appointment Confirmed: $_selectedConsultationType on $selectedDateString at ${booking.formattedTime} - ${booking.formattedEndTime} (Total: \$${totalEstimatedPrice.toStringAsFixed(2)})',
            timestamp: booking.formattedTime,
            isContract: false,
          );
          await chatRepository!.sendMessage(chatMessage);
        } catch (e) {
          debugPrint('Chat thread booking notification notice: $e');
        }
      }

      await loadBookings();
      return booking;
    } catch (e) {
      _errorMessage = 'Booking creation exception: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cancels an existing booking
  Future<bool> cancelBooking(String bookingId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await repository.cancelBooking(bookingId);
      if (success) {
        await loadBookings();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Booking cancellation error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
