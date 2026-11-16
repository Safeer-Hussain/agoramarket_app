import 'package:agora_market_app/core/theme/app_theme.dart';
import 'package:agora_market_app/core/theme/theme_provider.dart';
import 'package:agora_market_app/presentation/booking/booking_provider.dart';
import 'package:agora_market_app/presentation/booking/talent_booking_modal.dart';
import 'package:agora_market_app/presentation/profile/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mocks/mock_repositories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Sprint 28: TalentBookingModal renders and is 800x360 landscape safe with conflict detection',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final mockBookingRepo = MockBookingRepository();
      final mockChatRepo = MockChatRepository();
      final bookingProvider = BookingProvider(
        repository: mockBookingRepo,
        chatRepository: mockChatRepo,
      );

      final profileProvider = ProfileProvider(
        profileRepository: MockProfileRepository(),
        marketplaceRepository: MockMarketplaceRepository(),
        prefs: prefs,
      );

      // Verify on 800x360 landscape viewport
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>(
              create: (_) => ThemeProvider(prefs: prefs),
            ),
            ChangeNotifierProvider<ProfileProvider>.value(
              value: profileProvider,
            ),
            ChangeNotifierProvider<BookingProvider>.value(
              value: bookingProvider,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Center(
                child: Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () {
                        TalentBookingModal.show(
                          context,
                          creatorId: 'user_safeer_001',
                          creatorName: 'Safeer Hussain',
                          hourlyRate: 95.0,
                        );
                      },
                      child: const Text('Open Booking Modal'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Open the modal
      await tester.tap(find.text('Open Booking Modal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 2. Verify modal renders and components exist
      expect(find.byType(TalentBookingModal), findsOneWidget);
      expect(find.text('Schedule with Safeer Hussain'), findsOneWidget);
      expect(find.text('Select Date'), findsOneWidget);
      expect(find.text('Consultation Scope'), findsOneWidget);
      expect(find.text('1:1 Architecture Review'), findsOneWidget);
      expect(find.text('Session Duration'), findsOneWidget);
      expect(find.text('Available Time Slots'), findsOneWidget);

      // 3. Verify Seed Booking Conflict displays 'Booked' badge for 10:00 AM on tomorrow
      expect(find.text('Booked'), findsOneWidget);

      // 4. Select an open slot (02:00 PM / 14:00)
      final slotFinder = find.text('02:00 PM');
      await tester.scrollUntilVisible(
        slotFinder,
        100.0,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pump();
      expect(slotFinder, findsOneWidget);
      await tester.tap(slotFinder);
      await tester.pump();

      // 5. Scroll down in landscape and verify confirm button
      final confirmButtonFinder = find.text('Confirm Booking & Deposit Escrow');
      await tester.scrollUntilVisible(
        confirmButtonFinder,
        150.0,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pump();

      expect(confirmButtonFinder, findsOneWidget);

      // 6. Tap confirm and verify booking creation
      await tester.tap(confirmButtonFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify no RenderFlex overflow exceptions occurred
      expect(tester.takeException(), isNull);
    },
  );
}
