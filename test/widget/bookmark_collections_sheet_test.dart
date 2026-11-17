import 'package:agora_market_app/core/theme/app_theme.dart';
import 'package:agora_market_app/core/theme/theme_provider.dart';
import 'package:agora_market_app/presentation/feed/video_feed_provider.dart';
import 'package:agora_market_app/presentation/feed/widgets/bookmark_collections_sheet.dart';
import 'package:agora_market_app/presentation/feed/widgets/save_to_folder_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mocks/mock_repositories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Sprint 29: BookmarkCollectionsSheet renders and is 800x360 landscape safe',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final mockRepo = MockMarketplaceRepository();
      final feedProvider = VideoFeedProvider(repository: mockRepo);

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
            ChangeNotifierProvider<VideoFeedProvider>.value(
              value: feedProvider,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Center(
                child: Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () => BookmarkCollectionsSheet.show(context),
                      child: const Text('Open Collections Sheet'),
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

      // 1. Open Collections Sheet
      await tester.tap(find.text('Open Collections Sheet'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 2. Verify sheet components
      expect(find.byType(BookmarkCollectionsSheet), findsOneWidget);
      expect(find.text('Bookmark Collections & Taxonomy'), findsOneWidget);
      expect(find.text('Collections'), findsOneWidget);

      // 3. Verify folder chip exists
      expect(find.text('All Collections (1)'), findsOneWidget);

      // 4. Verify no RenderFlex overflow
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Sprint 29: SaveToFolderModal renders and saves pitch to collection on 800x360 landscape viewport',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final mockRepo = MockMarketplaceRepository();
      final feedProvider = VideoFeedProvider(repository: mockRepo);
      await feedProvider.loadPitches();
      final testPitch = feedProvider.pitches.first;

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
            ChangeNotifierProvider<VideoFeedProvider>.value(
              value: feedProvider,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Center(
                child: Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () =>
                          SaveToFolderModal.show(context, testPitch),
                      child: const Text('Open Save Modal'),
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

      // 1. Open SaveToFolderModal
      await tester.tap(find.text('Open Save Modal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 2. Verify modal elements
      expect(find.byType(SaveToFolderModal), findsOneWidget);
      expect(find.text('Save to Collection'), findsOneWidget);
      expect(find.text('Target Collection Folder'), findsOneWidget);
      expect(find.text('Taxonomy Tags'), findsOneWidget);

      // 3. Scroll to save button and tap
      final saveButtonFinder = find.text('Save to Collection Folder');
      await tester.scrollUntilVisible(
        saveButtonFinder,
        150.0,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pump();

      expect(saveButtonFinder, findsOneWidget);
      await tester.tap(saveButtonFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 4. Verify no RenderFlex overflow
      expect(tester.takeException(), isNull);
    },
  );
}
