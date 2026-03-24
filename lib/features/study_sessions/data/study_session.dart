class StudySession {
  const StudySession({
    this.id,
    required this.courseId,
    required this.startedAt,
    required this.endedAt,
    required this.durationSeconds,
  });

  final int? id;
  final int courseId;
  final int startedAt;
  final int endedAt;
  final int durationSeconds;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'course_id': courseId,
      'started_at': startedAt,
      'ended_at': endedAt,
      'duration_seconds': durationSeconds,
    };
  }

  factory StudySession.fromMap(Map<String, Object?> map) {
    return StudySession(
      id: map['id'] as int?,
      courseId: map['course_id'] as int,
      startedAt: map['started_at'] as int,
      endedAt: map['ended_at'] as int,
      durationSeconds: map['duration_seconds'] as int,
    );
  }
}
