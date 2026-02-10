class Course {
  final int? id;
  final String name;
  final int createdAt;

  Course({
    this.id,
    required this.name,
    required this.createdAt,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt,
    };
  }

  factory Course.fromMap(Map<String, Object?> map) {
    return Course(
      id: map['id'] as int?,
      name: map['name'] as String,
      createdAt: map['created_at'] as int,
    );
  }
}
