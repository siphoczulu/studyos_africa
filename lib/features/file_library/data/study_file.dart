class StudyFile {
  const StudyFile({
    this.id,
    required this.name,
    required this.path,
    required this.type,
    required this.createdAt,
  });

  final int? id;
  final String name;
  final String path;
  final String type;
  final int createdAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'type': type,
      'created_at': createdAt,
    };
  }

  factory StudyFile.fromMap(Map<String, Object?> map) {
    return StudyFile(
      id: map['id'] as int?,
      name: map['name'] as String,
      path: map['path'] as String,
      type: map['type'] as String,
      createdAt: map['created_at'] as int,
    );
  }
}
