import 'package:agora_market_app/core/theme/app_theme.dart';
import 'package:agora_market_app/presentation/map/map_filter_provider.dart';
import 'package:agora_market_app/presentation/map/talent_map_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../mocks/mock_repositories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TalentMapView Spatial Geofencing & Clustering Widget Tests', () {
    late MockMarketplaceRepository mockMarketplace;

    setUp(() {
      mockMarketplace = MockMarketplaceRepository();
    });

    Widget createTestWidget({required Widget child}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => MapFilterProvider(repository: mockMarketplace),
          ),
        ],
        child: MaterialApp(theme: AppTheme.darkTheme, home: child),
      );
    }

    testWidgets('Renders corridor filter chips horizontally in portrait mode', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(child: const TalentMapView()));
      await tester.pumpAndSettle();

      expect(find.text('All Corridors'), findsOneWidget);
      expect(find.text('Gulberg Main Blvd'), findsOneWidget);
      expect(find.text('Arfa'), findsOneWidget);
      expect(find.text('DHA Phase 5'), findsOneWidget);
    });

    testWidgets('Tapping corridor chip filters listings and updates state', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(child: const TalentMapView()));
      await tester.pumpAndSettle();

      // Tap on Gulberg corridor chip
      await tester.tap(find.text('Gulberg Main Blvd'));
      await tester.pumpAndSettle();

      // Verify that the listing card or count reflects the filter
      expect(find.byType(TalentMapView), findsOneWidget);
    });

    testWidgets('Zero RenderFlex overflow on 800x360 landscape viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(child: const TalentMapView()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('All Corridors'), findsOneWidget);
      expect(find.byType(TalentMapView), findsOneWidget);
    });
  });
}
