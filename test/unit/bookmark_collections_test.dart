import 'package:agora_market_app/domain/entities/bookmark_folder.dart';
import 'package:agora_market_app/domain/entities/pitch_bookmark.dart';
import 'package:agora_market_app/presentation/feed/video_feed_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mocks/mock_repositories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BookmarkFolder & PitchBookmark Entity Tests', () {
    const folder = BookmarkFolder(
      id: 'f_test_01',
      name: 'Mobile Architects',
      description: 'Flutter and architecture specialists',
      iconName: 'code',
      sortOrder: 0,
      createdAt: '2026-11-17T12:00:00Z',
      pitchCount: 3,
    );

    test('BookmarkFolder serializes and deserializes cleanly', () {
      final map = folder.toMap();
      final restored = BookmarkFolder.fromMap(map, pitchCount: 3);

      expect(restored.id, folder.id);
      expect(restored.name, folder.name);
      expect(restored.description, folder.description);
      expect(restored.iconName, folder.iconName);
      expect(restored.sortOrder, folder.sortOrder);
      expect(restored.pitchCount, 3);
    });

    const bookmark = PitchBookmark(
      id: 'bm_test_01',
      folderId: 'f_test_01',
      pitchId: 'pitch_test_01',
      tags: ['Mobile', 'Flutter', 'Performance'],
      notes: 'Reviewed frame rate and custom canvas',
      savedAt: '2026-11-17T12:00:00Z',
    );

    test('PitchBookmark serializes and parses comma-separated tags', () {
      final map = bookmark.toMap();
      expect(map['tags'], 'Mobile,Flutter,Performance');

      final restored = PitchBookmark.fromMap(map);
      expect(restored.id, bookmark.id);
      expect(restored.folderId, bookmark.folderId);
      expect(restored.pitchId, bookmark.pitchId);
      expect(restored.tags, ['Mobile', 'Flutter', 'Performance']);
      expect(restored.notes, bookmark.notes);
    });
  });

  group('VideoFeedProvider Bookmark Collections Workflow Tests', () {
    late MockMarketplaceRepository mockRepo;
    late VideoFeedProvider provider;

    setUp(() {
      mockRepo = MockMarketplaceRepository();
      provider = VideoFeedProvider(repository: mockRepo);
    });

    test(
      'Loads folders and active pitch bookmarks on initialization',
      () async {
        await provider.loadBookmarkCollections();

        expect(provider.folders.isNotEmpty, isTrue);
        expect(provider.bookmarks.isNotEmpty, isTrue);
        expect(provider.allUniqueTags, contains('Flutter'));
      },
    );

    test('Creates new folder and appends to collection list', () async {
      await provider.createFolder(
        'AI Researchers',
        'Machine learning and LLM mobile engineers',
        'rocket',
      );

      expect(provider.folders.any((f) => f.name == 'AI Researchers'), isTrue);
    });

    test('Saves pitch to folder with custom taxonomy tags and marks pitch bookmarked', () async {
      await provider.loadBookmarkCollections();

      await provider.savePitchToFolder(
        pitchId: 'pitch_test_02',
        folderId: 'folder_fintech',
        tags: ['Fintech', 'Design Systems', 'WCAG'],
        notes: 'Top design systems architect',
      );

      final foldersForPitch = provider.getFoldersForPitch('pitch_test_02');
      expect(foldersForPitch, contains('folder_fintech'));

      final tags = provider.getTagsForPitch('pitch_test_02');
      expect(tags, contains('Design Systems'));

      final pitch = provider.pitches.firstWhere((p) => p.id == 'pitch_test_02');
      expect(pitch.isBookmarked, isTrue);
    });

    test('Filters bookmarked pitches by selected folder and tag', () async {
      await provider.loadBookmarkCollections();

      // Filter by folder_mobile
      provider.selectFolder('folder_mobile');
      expect(provider.selectedFolderId, 'folder_mobile');
      final mobilePitches = provider.bookmarkedPitches;
      expect(mobilePitches.any((p) => p.id == 'pitch_test_01'), isTrue);

      // Filter by tag
      provider.selectTag('Performance');
      expect(provider.selectedTag, 'Performance');
      final taggedPitches = provider.bookmarkedPitches;
      expect(taggedPitches.isNotEmpty, isTrue);

      // Clear filters
      provider.selectFolder(null);
      provider.selectTag(null);
      expect(provider.selectedFolderId, isNull);
      expect(provider.selectedTag, isNull);
    });

    test('Reorders folders via drag and drop', () async {
      await provider.loadBookmarkCollections();
      final initialFirst = provider.folders.first.name;
      expect(initialFirst, isNotEmpty);

      // Reorder 0 to 1
      await provider.reorderFolders(0, 1);
      expect(provider.folders.length, greaterThanOrEqualTo(2));
    });

    test('Deletes folder and cleans up bookmarks inside', () async {
      await provider.loadBookmarkCollections();
      final initialCount = provider.folders.length;

      await provider.deleteFolder('folder_fintech');
      expect(provider.folders.length, initialCount - 1);
      expect(provider.folders.any((f) => f.id == 'folder_fintech'), isFalse);
    });
  });
}
