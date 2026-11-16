class TalentBooking {
  final String id;
  final String creatorId;
  final String creatorName;
  final String clientName;
  final String consultationType;
  final String bookingDate; // YYYY-MM-DD
  final String startTime; // HH:mm (24-hour format)
  final int durationMinutes;
  final double ratePerHour;
  final double totalPrice;
  final String status; // CONFIRMED, CANCELLED
  final String notes;
  final String createdAt;

  const TalentBooking({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    required this.clientName,
    required this.consultationType,
    required this.bookingDate,
    required this.startTime,
    required this.durationMinutes,
    required this.ratePerHour,
    required this.totalPrice,
    required this.status,
    required this.notes,
    required this.createdAt,
  });

  /// Calculates start time as minutes from midnight (0..1440)
  int get startMinutes {
    final parts = startTime.split(':');
    if (parts.length != 2) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return (h * 60) + m;
  }

  /// Calculates end time as minutes from midnight
  int get endMinutes => startMinutes + durationMinutes;

  /// Returns 12-hour formatted time with AM/PM (e.g. "09:00 AM", "02:30 PM")
  String get formattedTime {
    final parts = startTime.split(':');
    if (parts.length != 2) return startTime;
    int hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final period = hour >= 12 ? 'PM' : 'AM';
    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }
    final minuteStr = minute.toString().padLeft(2, '0');
    final hourStr = hour.toString().padLeft(2, '0');
    return '$hourStr:$minuteStr $period';
  }

  /// Returns formatted end time with AM/PM
  String get formattedEndTime {
    final endTotal = endMinutes;
    int endHour = (endTotal ~/ 60) % 24;
    final endMin = endTotal % 60;
    final period = endHour >= 12 ? 'PM' : 'AM';
    if (endHour == 0) {
      endHour = 12;
    } else if (endHour > 12) {
      endHour -= 12;
    }
    final minStr = endMin.toString().padLeft(2, '0');
    final hourStr = endHour.toString().padLeft(2, '0');
    return '$hourStr:$minStr $period';
  }

  /// Checks if another time slot overlaps with this booking on the same day
  bool overlaps(String otherStartTime, int otherDurationMinutes) {
    if (status == 'CANCELLED') return false;
    final parts = otherStartTime.split(':');
    if (parts.length != 2) return false;
    final otherH = int.tryParse(parts[0]) ?? 0;
    final otherM = int.tryParse(parts[1]) ?? 0;
    final otherStart = (otherH * 60) + otherM;
    final otherEnd = otherStart + otherDurationMinutes;

    return startMinutes < otherEnd && endMinutes > otherStart;
  }

  TalentBooking copyWith({
    String? id,
    String? creatorId,
    String? creatorName,
    String? clientName,
    String? consultationType,
    String? bookingDate,
    String? startTime,
    int? durationMinutes,
    double? ratePerHour,
    double? totalPrice,
    String? status,
    String? notes,
    String? createdAt,
  }) {
    return TalentBooking(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      clientName: clientName ?? this.clientName,
      consultationType: consultationType ?? this.consultationType,
      bookingDate: bookingDate ?? this.bookingDate,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      ratePerHour: ratePerHour ?? this.ratePerHour,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'creator_id': creatorId,
      'creator_name': creatorName,
      'client_name': clientName,
      'consultation_type': consultationType,
      'booking_date': bookingDate,
      'start_time': startTime,
      'duration_minutes': durationMinutes,
      'rate_per_hour': ratePerHour,
      'total_price': totalPrice,
      'status': status,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  factory TalentBooking.fromMap(Map<String, dynamic> map) {
    return TalentBooking(
      id: map['id'] as String,
      creatorId: map['creator_id'] as String,
      creatorName: map['creator_name'] as String,
      clientName: map['client_name'] as String,
      consultationType: map['consultation_type'] as String,
      bookingDate: map['booking_date'] as String,
      startTime: map['start_time'] as String,
      durationMinutes: (map['duration_minutes'] as num).toInt(),
      ratePerHour: (map['rate_per_hour'] as num).toDouble(),
      totalPrice: (map['total_price'] as num).toDouble(),
      status: map['status'] as String,
      notes: map['notes'] as String,
      createdAt: map['created_at'] as String,
    );
  }
}
