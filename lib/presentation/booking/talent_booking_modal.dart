import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/app_feedback.dart';
import '../../core/utils/currency_converter.dart';
import '../profile/profile_provider.dart';
import 'booking_provider.dart';
import 'widgets/custom_calendar_strip.dart';

class TalentBookingModal extends StatefulWidget {
  final String creatorId;
  final String creatorName;
  final double hourlyRate;

  const TalentBookingModal({
    super.key,
    required this.creatorId,
    required this.creatorName,
    required this.hourlyRate,
  });

  static Future<void> show(
    BuildContext context, {
    required String creatorId,
    required String creatorName,
    required double hourlyRate,
  }) {
    final bookingProvider = Provider.of<BookingProvider>(
      context,
      listen: false,
    );
    bookingProvider.initialize(
      creatorId: creatorId,
      creatorName: creatorName,
      hourlyRate: hourlyRate,
    );

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TalentBookingModal(
        creatorId: creatorId,
        creatorName: creatorName,
        hourlyRate: hourlyRate,
      ),
    );
  }

  @override
  State<TalentBookingModal> createState() => _TalentBookingModalState();
}

class _TalentBookingModalState extends State<TalentBookingModal> {
  final TextEditingController _notesController = TextEditingController();
  bool _showMyBookings = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final bookingProvider = Provider.of<BookingProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context);
    final activeCurrency = profileProvider.selectedCurrency;

    final selectedTypeInfo = BookingProvider.consultationTypes.firstWhere(
      (t) => t.title == bookingProvider.selectedConsultationType,
      orElse: () => BookingProvider.consultationTypes.first,
    );

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.calendar_month_rounded,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Schedule with ${widget.creatorName}',
                          style: TextStyle(
                            fontSize: isLandscape ? 15 : 17,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Real-time availability, conflict prevention & escrow deposit',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _showMyBookings
                          ? Icons.add_circle_outline_rounded
                          : Icons.event_note_rounded,
                      color: colorScheme.secondary,
                      size: 20,
                    ),
                    tooltip: _showMyBookings
                        ? 'Book Slot'
                        : 'View Scheduled Sessions',
                    onPressed: () {
                      setState(() => _showMyBookings = !_showMyBookings);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (bookingProvider.errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: colorScheme.error,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          bookingProvider.errorMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              if (_showMyBookings)
                _buildScheduledBookingsView(
                  context,
                  bookingProvider,
                  colorScheme,
                )
              else
                _buildBookingForm(
                  context,
                  bookingProvider,
                  colorScheme,
                  activeCurrency,
                  selectedTypeInfo,
                  isLandscape,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingForm(
    BuildContext context,
    BookingProvider bookingProvider,
    ColorScheme colorScheme,
    String activeCurrency,
    ConsultationTypeInfo selectedTypeInfo,
    bool isLandscape,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Calendar Day Strip
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select Date',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              bookingProvider.selectedDateString,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        CustomCalendarStrip(
          selectedDate: bookingProvider.selectedDate,
          onDateSelected: (date) => bookingProvider.selectDate(date),
          hasBookings: (date) => bookingProvider.dateHasBookings(date),
        ),
        const SizedBox(height: 16),

        // 2. Consultation Scope Type
        Text(
          'Consultation Scope',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: BookingProvider.consultationTypes.map((type) {
            final isSel =
                bookingProvider.selectedConsultationType == type.title;
            return ChoiceChip(
              label: Text(
                type.title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                  color: isSel ? colorScheme.onPrimary : colorScheme.onSurface,
                ),
              ),
              selected: isSel,
              selectedColor: colorScheme.primary,
              backgroundColor: colorScheme.surfaceContainerHighest,
              onSelected: (val) {
                if (val) bookingProvider.selectConsultationType(type.title);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            selectedTypeInfo.description,
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 3. Duration Horizon Chips
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Session Duration',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              '${bookingProvider.selectedDurationMinutes} Minutes',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: BookingProvider.durationOptions.map((mins) {
            final isSel = bookingProvider.selectedDurationMinutes == mins;
            return ChoiceChip(
              label: Text(
                '$mins min',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                  color: isSel
                      ? colorScheme.onSecondary
                      : colorScheme.onSurface,
                ),
              ),
              selected: isSel,
              selectedColor: colorScheme.secondary,
              backgroundColor: colorScheme.surfaceContainerHighest,
              onSelected: (val) {
                if (val) bookingProvider.selectDuration(mins);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // 4. Time Slot Grid with Conflict Indication
        Text(
          'Available Time Slots',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BookingProvider.standardTimeSlots.map((slot) {
            final isConflict = bookingProvider.isSlotConflict(slot);
            final isSelected = bookingProvider.selectedTimeSlot == slot;

            final parts = slot.split(':');
            int h = int.tryParse(parts[0]) ?? 0;
            final m = parts.length > 1 ? parts[1] : '00';
            final period = h >= 12 ? 'PM' : 'AM';
            if (h > 12) h -= 12;
            final formattedSlot = '${h.toString().padLeft(2, '0')}:$m $period';

            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: isConflict
                  ? null
                  : () => bookingProvider.selectTimeSlot(slot),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isConflict
                      ? colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.4,
                        )
                      : (isSelected
                            ? colorScheme.primary
                            : colorScheme.surfaceContainerHighest),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isConflict
                        ? colorScheme.outlineVariant.withValues(alpha: 0.3)
                        : (isSelected
                              ? colorScheme.primary
                              : colorScheme.outlineVariant),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formattedSlot,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : (isConflict
                                  ? FontWeight.normal
                                  : FontWeight.w600),
                        decoration: isConflict
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: isConflict
                            ? colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.5,
                              )
                            : (isSelected
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface),
                      ),
                    ),
                    if (isConflict) ...[
                      const SizedBox(width: 4),
                      Text(
                        'Booked',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // 5. Notes / Agenda
        TextField(
          controller: _notesController,
          onChanged: (val) => bookingProvider.setNotes(val),
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Agenda / Technical Requirements (Optional)',
            hintText: 'Share repositories, sprint goals, or bug logs...',
            hintStyle: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 6. Escrow Fee Telemetry Breakdown
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            children: [
              _buildTelemetryRow(
                context,
                label: 'Talent Rate Basis',
                value:
                    '${CurrencyConverter.format(bookingProvider.hourlyRate, activeCurrency)}/hr',
                textColor: colorScheme.onSurface,
              ),
              const SizedBox(height: 6),
              _buildTelemetryRow(
                context,
                label:
                    'Session Duration (${bookingProvider.selectedDurationMinutes}m)',
                value: CurrencyConverter.format(
                  bookingProvider.calculatedSubtotal,
                  activeCurrency,
                ),
                textColor: colorScheme.onSurface,
              ),
              const SizedBox(height: 6),
              _buildTelemetryRow(
                context,
                label: 'Escrow Protection Guarantee (5%)',
                value: CurrencyConverter.format(
                  bookingProvider.platformEscrowFee,
                  activeCurrency,
                ),
                textColor: colorScheme.secondary,
              ),
              const Divider(height: 16),
              _buildTelemetryRow(
                context,
                label: 'Total Escrow Deposit',
                value: CurrencyConverter.format(
                  bookingProvider.totalEstimatedPrice,
                  activeCurrency,
                ),
                textColor: colorScheme.primary,
                isBold: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 7. Confirm Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: bookingProvider.isLoading
                ? null
                : () async {
                    final booking = await bookingProvider.confirmBooking();
                    if (booking != null && context.mounted) {
                      Navigator.of(context).pop();
                      AppFeedback.showSuccess(
                        context,
                        'Consultation session confirmed for ${booking.formattedTime} on ${booking.bookingDate}',
                      );
                    }
                  },
            icon: bookingProvider.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_rounded, size: 18),
            label: Text(
              'Confirm Booking & Deposit Escrow',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduledBookingsView(
    BuildContext context,
    BookingProvider bookingProvider,
    ColorScheme colorScheme,
  ) {
    final bookings = bookingProvider.creatorBookings;

    if (bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              Icon(
                Icons.event_busy_rounded,
                size: 40,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                'No Scheduled Consultations',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'No active appointments booked with this talent yet.',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Scheduled Appointments (${bookings.length})',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bookings.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final b = bookings[index];
            final isCancelled = b.status == 'CANCELLED';

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCancelled
                      ? colorScheme.outlineVariant.withValues(alpha: 0.3)
                      : colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCancelled
                          ? colorScheme.surfaceContainerHighest
                          : colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.event_available_rounded,
                      color: isCancelled
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.consultationType,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isCancelled
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onSurface,
                            decoration: isCancelled
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${b.bookingDate} • ${b.formattedTime} - ${b.formattedEndTime} (${b.durationMinutes}m)',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (b.notes.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            b.notes,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!isCancelled)
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () async {
                        final ok = await bookingProvider.cancelBooking(b.id);
                        if (ok && context.mounted) {
                          AppFeedback.showSuccess(
                            context,
                            'Appointment on ${b.bookingDate} cancelled.',
                          );
                        }
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 11),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Cancelled',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTelemetryRow(
    BuildContext context, {
    required String label,
    required String value,
    required Color textColor,
    bool isBold = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: textColor,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
