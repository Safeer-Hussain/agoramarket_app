class PitchBookmark {
  final String id;
  final String folderId;
  final String pitchId;
  final List<String> tags;
  final String notes;
  final String savedAt;

  const PitchBookmark({
    required this.id,
    required this.folderId,
    required this.pitchId,
    required this.tags,
    required this.notes,
    required this.savedAt,
  });

  PitchBookmark copyWith({
    String? id,
    String? folderId,
    String? pitchId,
    List<String>? tags,
    String? notes,
    String? savedAt,
  }) {
    return PitchBookmark(
      id: id ?? this.id,
      folderId: folderId ?? this.folderId,
      pitchId: pitchId ?? this.pitchId,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'folder_id': folderId,
      'pitch_id': pitchId,
      'tags': tags.join(','),
      'notes': notes,
      'saved_at': savedAt,
    };
  }

  factory PitchBookmark.fromMap(Map<String, dynamic> map) {
    final rawTags = map['tags'] as String? ?? '';
    final parsedTags = rawTags.isEmpty
        ? <String>[]
        : rawTags
              .split(',')
              .map((t) => t.trim())
              .where((t) => t.isNotEmpty)
              .toList();

    return PitchBookmark(
      id: map['id'] as String,
      folderId: map['folder_id'] as String,
      pitchId: map['pitch_id'] as String,
      tags: parsedTags,
      notes: map['notes'] as String? ?? '',
      savedAt: map['saved_at'] as String,
    );
  }
}
