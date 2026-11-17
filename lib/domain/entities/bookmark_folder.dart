class BookmarkFolder {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final int sortOrder;
  final String createdAt;
  final int pitchCount;

  const BookmarkFolder({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.sortOrder,
    required this.createdAt,
    this.pitchCount = 0,
  });

  BookmarkFolder copyWith({
    String? id,
    String? name,
    String? description,
    String? iconName,
    int? sortOrder,
    String? createdAt,
    int? pitchCount,
  }) {
    return BookmarkFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      pitchCount: pitchCount ?? this.pitchCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_name': iconName,
      'sort_order': sortOrder,
      'created_at': createdAt,
    };
  }

  factory BookmarkFolder.fromMap(
    Map<String, dynamic> map, {
    int pitchCount = 0,
  }) {
    return BookmarkFolder(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      iconName: map['icon_name'] as String,
      sortOrder: (map['sort_order'] as num).toInt(),
      createdAt: map['created_at'] as String,
      pitchCount: pitchCount,
    );
  }
}
