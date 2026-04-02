class TimetableBlock {
  final int? id;
  final int courseId;
  final int weekday;
  final int startMinutes;
  final int endMinutes;

  TimetableBlock({
    this.id,
    required this.courseId,
    required this.weekday,
    required this.startMinutes,
    required this.endMinutes,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'course_id': courseId,
      'weekday': weekday,
      'start_minutes': startMinutes,
      'end_minutes': endMinutes,
    };
  }

  factory TimetableBlock.fromMap(Map<String, Object?> map) {
    return TimetableBlock(
      id: map['id'] as int?,
      courseId: map['course_id'] as int,
      weekday: map['weekday'] as int,
      startMinutes: map['start_minutes'] as int,
      endMinutes: map['end_minutes'] as int,
    );
  }
}
