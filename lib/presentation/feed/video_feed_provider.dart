import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/bookmark_folder.dart';
import '../../domain/entities/pitch_bookmark.dart';
import '../../domain/entities/video_pitch.dart';
import '../../domain/entities/comment.dart';
import '../../domain/repositories/marketplace_repository.dart';

class VideoFeedProvider extends ChangeNotifier {
  final MarketplaceRepository repository;
  final Uuid _uuid = const Uuid();

  List<VideoPitch> _pitches = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentIndex = 0;

  // Video playback controls
  bool _isPlaying = true;
  bool _isMuted = false;
  double _playbackSpeed = 1.0;
  double _playbackProgress = 0.35;

  final Map<String, List<Comment>> _commentsCache = {};
  bool _disposed = false;

  // Bookmark collections and taxonomy
  List<BookmarkFolder> _folders = [];
  List<PitchBookmark> _bookmarks = [];
  String? _selectedFolderId;
  String? _selectedTag;

  VideoFeedProvider({required this.repository}) {
    loadPitches();
    loadBookmarkCollections();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  List<VideoPitch> get pitches => _pitches;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentIndex => _currentIndex;
  VideoPitch? get currentPitch =>
      _pitches.isNotEmpty && _currentIndex < _pitches.length
      ? _pitches[_currentIndex]
      : null;

  bool get isPlaying => _isPlaying;
  bool get isMuted => _isMuted;
  double get playbackSpeed => _playbackSpeed;
  double get playbackProgress => _playbackProgress;

  List<Comment> getCommentsForPitch(String pitchId) =>
      _commentsCache[pitchId] ?? [];

  void setIndex(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    _playbackProgress = 0.0;
    _isPlaying = true;
    notifyListeners();
  }

  void togglePlayPause() {
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    notifyListeners();
  }

  void cyclePlaybackSpeed() {
    if (_playbackSpeed == 1.0) {
      _playbackSpeed = 1.5;
    } else if (_playbackSpeed == 1.5) {
      _playbackSpeed = 2.0;
    } else {
      _playbackSpeed = 1.0;
    }
    notifyListeners();
  }

  void setPlaybackProgress(double progress) {
    _playbackProgress = progress.clamp(0.0, 1.0);
    notifyListeners();
  }

  Future<void> loadPitches() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _pitches = await repository.getVideoPitches();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleLike(String pitchId) async {
    final idx = _pitches.indexWhere((p) => p.id == pitchId);
    if (idx == -1) return;

    final target = _pitches[idx];
    final newIsLiked = !target.isLiked;
    final newCount = newIsLiked ? target.likesCount + 1 : target.likesCount - 1;

    _pitches[idx] = target.copyWith(
      isLiked: newIsLiked,
      likesCount: newCount < 0 ? 0 : newCount,
    );
    notifyListeners();

    try {
      await repository.toggleLike(pitchId);
    } catch (_) {
      _pitches[idx] = target;
      notifyListeners();
    }
  }

  Future<void> toggleBookmark(String pitchId) async {
    final idx = _pitches.indexWhere((p) => p.id == pitchId);
    if (idx == -1) return;

    final target = _pitches[idx];
    final newIsBookmarked = !target.isBookmarked;
    final newCount = newIsBookmarked
        ? target.bookmarksCount + 1
        : target.bookmarksCount - 1;

    _pitches[idx] = target.copyWith(
      isBookmarked: newIsBookmarked,
      bookmarksCount: newCount < 0 ? 0 : newCount,
    );
    notifyListeners();

    try {
      await repository.toggleBookmark(pitchId);
    } catch (_) {
      _pitches[idx] = target;
      notifyListeners();
    }
  }

  Future<void> loadComments(String pitchId) async {
    try {
      final comments = await repository.getComments(pitchId);
      _commentsCache[pitchId] = comments;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> addComment(String pitchId, String content) async {
    if (content.trim().isEmpty) return;

    final newComment = Comment(
      id: 'comment_${_uuid.v4()}',
      pitchId: pitchId,
      authorName: 'Safeer Hussain',
      authorAvatar: 'assets/images/avatar_safeer.png',
      content: content.trim(),
      createdAt: 'Just now',
    );

    final currentList = _commentsCache[pitchId] ?? [];
    _commentsCache[pitchId] = [newComment, ...currentList];
    notifyListeners();

    try {
      await repository.addComment(newComment);
    } catch (_) {}
  }

  Future<void> createVideoPitch({
    required String title,
    required String role,
    required double hourlyRate,
    required String currency,
    required String locationName,
    required String category,
    required String pitchScript,
    required List<String> skills,
  }) async {
    final id = 'pitch_${_uuid.v4()}';
    String thumbnailAsset = 'assets/images/thumb_mobile_arch.png';
    if (category == 'Freelancer') {
      thumbnailAsset = 'assets/images/thumb_ui_ux.png';
    } else if (category == 'Agency') {
      thumbnailAsset = 'assets/images/thumb_cloud_devops.png';
    } else if (category == 'Job') {
      thumbnailAsset = 'assets/images/thumb_ai_automation.png';
    }

    final newPitch = VideoPitch(
      id: id,
      title: title,
      creatorName: 'Safeer Hussain',
      creatorAvatar: 'assets/images/avatar_safeer.png',
      role: role,
      hourlyRate: hourlyRate,
      currency: currency,
      locationName: locationName,
      latitude: 31.5204,
      longitude: 74.3587,
      category: category,
      videoAsset: thumbnailAsset,
      thumbnailAsset: thumbnailAsset,
      likesCount: 0,
      bookmarksCount: 0,
      isLiked: false,
      isBookmarked: false,
      pitchScript: pitchScript,
      skills: skills,
      createdAt: DateTime.now().toIso8601String(),
    );

    _pitches.insert(0, newPitch);
    _currentIndex = 0;
    notifyListeners();

    await repository.addVideoPitch(newPitch);
  }

  // ==========================================
  // BOOKMARK COLLECTIONS & TAXONOMY METHODS
  // ==========================================

  List<BookmarkFolder> get folders => _folders;
  List<PitchBookmark> get bookmarks => _bookmarks;
  String? get selectedFolderId => _selectedFolderId;
  String? get selectedTag => _selectedTag;

  List<String> get allUniqueTags {
    final set = <String>{};
    for (final b in _bookmarks) {
      set.addAll(b.tags);
    }
    final list = set.toList();
    list.sort();
    return list;
  }

  List<VideoPitch> get bookmarkedPitches {
    return _pitches.where((pitch) {
      final matchingBookmarks = _bookmarks.where((b) => b.pitchId == pitch.id);
      if (matchingBookmarks.isEmpty) return false;

      if (_selectedFolderId != null) {
        final inFolder = matchingBookmarks.any(
          (b) => b.folderId == _selectedFolderId,
        );
        if (!inFolder) return false;
      }

      if (_selectedTag != null && _selectedTag!.isNotEmpty) {
        final hasTag = matchingBookmarks.any(
          (b) => b.tags.contains(_selectedTag),
        );
        if (!hasTag) return false;
      }

      return true;
    }).toList();
  }

  Future<void> loadBookmarkCollections() async {
    try {
      _folders = await repository.getBookmarkFolders();
      _bookmarks = await repository.getAllBookmarks();

      // Sync pitches with active bookmarks
      final bookmarkedPitchIds = _bookmarks.map((b) => b.pitchId).toSet();
      bool changed = false;
      for (int i = 0; i < _pitches.length; i++) {
        final shouldBeBookmarked = bookmarkedPitchIds.contains(_pitches[i].id);
        if (_pitches[i].isBookmarked != shouldBeBookmarked) {
          _pitches[i] = _pitches[i].copyWith(isBookmarked: shouldBeBookmarked);
          changed = true;
        }
      }
      if (changed) notifyListeners();
    } catch (e) {
      debugPrint('Bookmark collections load notice: $e');
    }
  }

  void selectFolder(String? folderId) {
    _selectedFolderId = folderId;
    notifyListeners();
  }

  void selectTag(String? tag) {
    _selectedTag = tag;
    notifyListeners();
  }

  Future<void> createFolder(
    String name,
    String description,
    String iconName,
  ) async {
    if (name.trim().isEmpty) return;

    final folder = BookmarkFolder(
      id: 'folder_${_uuid.v4()}',
      name: name.trim(),
      description: description.trim(),
      iconName: iconName,
      sortOrder: _folders.length,
      createdAt: DateTime.now().toIso8601String(),
    );

    await repository.createBookmarkFolder(folder);
    await loadBookmarkCollections();
  }

  Future<void> reorderFolders(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _folders.removeAt(oldIndex);
    _folders.insert(newIndex, item);
    notifyListeners();

    final orderedIds = _folders.map((f) => f.id).toList();
    await repository.updateBookmarkFolderOrder(orderedIds);
    await loadBookmarkCollections();
  }

  Future<void> deleteFolder(String folderId) async {
    await repository.deleteBookmarkFolder(folderId);
    if (_selectedFolderId == folderId) {
      _selectedFolderId = null;
    }
    await loadBookmarkCollections();
  }

  Future<void> savePitchToFolder({
    required String pitchId,
    required String folderId,
    required List<String> tags,
    String notes = '',
  }) async {
    final bookmark = PitchBookmark(
      id: 'bm_${_uuid.v4()}',
      folderId: folderId,
      pitchId: pitchId,
      tags: tags,
      notes: notes,
      savedAt: DateTime.now().toIso8601String(),
    );

    await repository.savePitchToFolder(bookmark);

    final idx = _pitches.indexWhere((p) => p.id == pitchId);
    if (idx != -1 && !_pitches[idx].isBookmarked) {
      _pitches[idx] = _pitches[idx].copyWith(
        isBookmarked: true,
        bookmarksCount: _pitches[idx].bookmarksCount + 1,
      );
    }

    await loadBookmarkCollections();
    notifyListeners();
  }

  Future<void> removePitchFromFolder(String pitchId, String folderId) async {
    await repository.removePitchFromFolder(pitchId, folderId);
    await loadBookmarkCollections();

    final stillSaved = _bookmarks.any((b) => b.pitchId == pitchId);
    if (!stillSaved) {
      final idx = _pitches.indexWhere((p) => p.id == pitchId);
      if (idx != -1) {
        _pitches[idx] = _pitches[idx].copyWith(
          isBookmarked: false,
          bookmarksCount: (_pitches[idx].bookmarksCount - 1).clamp(0, 999999),
        );
      }
    }
    notifyListeners();
  }

  List<String> getFoldersForPitch(String pitchId) {
    return _bookmarks
        .where((b) => b.pitchId == pitchId)
        .map((b) => b.folderId)
        .toSet()
        .toList();
  }

  List<String> getTagsForPitch(String pitchId) {
    final set = <String>{};
    for (final b in _bookmarks.where((b) => b.pitchId == pitchId)) {
      set.addAll(b.tags);
    }
    return set.toList();
  }
}
