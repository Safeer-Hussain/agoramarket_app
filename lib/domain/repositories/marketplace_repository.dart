import '../entities/bookmark_folder.dart';
import '../entities/pitch_bookmark.dart';
import '../entities/video_pitch.dart';
import '../entities/comment.dart';

abstract class MarketplaceRepository {
  Future<List<VideoPitch>> getVideoPitches();
  Future<void> toggleLike(String pitchId);
  Future<void> toggleBookmark(String pitchId);
  Future<void> addVideoPitch(VideoPitch pitch);
  Future<List<Comment>> getComments(String pitchId);
  Future<void> addComment(Comment comment);
  Future<List<VideoPitch>> searchPitches({
    String? query,
    String? category,
    double? maxRadiusKm,
    double? userLat,
    double? userLng,
    double? maxHourlyRate,
  });

  // Bookmark Collections & Taxonomy
  Future<List<BookmarkFolder>> getBookmarkFolders();
  Future<void> createBookmarkFolder(BookmarkFolder folder);
  Future<void> updateBookmarkFolderOrder(List<String> folderIdsInOrder);
  Future<void> deleteBookmarkFolder(String folderId);
  Future<List<PitchBookmark>> getBookmarksForFolder(String folderId);
  Future<List<PitchBookmark>> getAllBookmarks();
  Future<void> savePitchToFolder(PitchBookmark bookmark);
  Future<void> removePitchFromFolder(String pitchId, String folderId);
  Future<List<String>> getFoldersForPitch(String pitchId);
}
