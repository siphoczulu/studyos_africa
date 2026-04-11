import 'package:flutter_test/flutter_test.dart';
import 'package:studyos_africa/features/courses/data/course.dart';
import 'package:studyos_africa/features/courses/domain/today_plan_recommender.dart';
import 'package:studyos_africa/features/study_sessions/data/study_session.dart';

void main() {
  group('TodayPlanRecommender.recommendCourse', () {
    test('returns null when there are no courses', () {
      final recommendedCourse = TodayPlanRecommender.recommendCourse(
        courses: const [],
        sessions: const [],
      );

      expect(recommendedCourse, isNull);
    });

    test('returns the first never-studied course when one exists', () {
      final courses = [
        _course(id: 1, name: 'Math'),
        _course(id: 2, name: 'Biology'),
      ];
      final sessions = [_session(courseId: 1, endedAt: 300)];

      final recommendedCourse = TodayPlanRecommender.recommendCourse(
        courses: courses,
        sessions: sessions,
      );

      expect(recommendedCourse, same(courses[1]));
    });

    test('returns course whose latest study session is oldest', () {
      final courses = [
        _course(id: 1, name: 'Math'),
        _course(id: 2, name: 'Biology'),
        _course(id: 3, name: 'Physics'),
      ];
      final sessions = [
        _session(courseId: 1, endedAt: 500),
        _session(courseId: 2, endedAt: 300),
        _session(courseId: 3, endedAt: 700),
      ];

      final recommendedCourse = TodayPlanRecommender.recommendCourse(
        courses: courses,
        sessions: sessions,
      );

      expect(recommendedCourse, same(courses[1]));
    });

    test('ignores sessions for unknown courses', () {
      final courses = [
        _course(id: 1, name: 'Math'),
        _course(id: 2, name: 'Biology'),
      ];
      final sessions = [
        _session(courseId: 99, endedAt: 100),
        _session(courseId: 1, endedAt: 200),
      ];

      final recommendedCourse = TodayPlanRecommender.recommendCourse(
        courses: courses,
        sessions: sessions,
      );

      expect(recommendedCourse, same(courses[1]));
    });

    test('uses latest session per course when comparing courses', () {
      final courses = [
        _course(id: 1, name: 'Math'),
        _course(id: 2, name: 'Biology'),
      ];
      final sessions = [
        _session(courseId: 1, endedAt: 100),
        _session(courseId: 1, endedAt: 600),
        _session(courseId: 2, endedAt: 500),
      ];

      final recommendedCourse = TodayPlanRecommender.recommendCourse(
        courses: courses,
        sessions: sessions,
      );

      expect(recommendedCourse, same(courses[1]));
    });
  });
}

Course _course({required int id, required String name}) {
  return Course(id: id, name: name, createdAt: 0);
}

StudySession _session({required int courseId, required int endedAt}) {
  return StudySession(
    courseId: courseId,
    startedAt: endedAt - 60,
    endedAt: endedAt,
    durationSeconds: 60,
  );
}
