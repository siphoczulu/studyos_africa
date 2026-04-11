import '../data/course.dart';
import '../../study_sessions/data/study_session.dart';

class TodayPlanRecommender {
  const TodayPlanRecommender._();

  static Course? recommendCourse({
    required List<Course> courses,
    required List<StudySession> sessions,
  }) {
    if (courses.isEmpty) {
      return null;
    }

    final latestSessionByCourseId = <int, StudySession>{};
    for (final session in sessions) {
      final existing = latestSessionByCourseId[session.courseId];
      if (existing == null || session.endedAt > existing.endedAt) {
        latestSessionByCourseId[session.courseId] = session;
      }
    }

    for (final course in courses) {
      final courseId = course.id;
      if (courseId == null || !latestSessionByCourseId.containsKey(courseId)) {
        return course;
      }
    }

    Course? recommendedCourse;
    StudySession? oldestLatestSession;

    for (final course in courses) {
      final courseId = course.id;
      if (courseId == null) {
        continue;
      }

      final latestSession = latestSessionByCourseId[courseId];
      if (latestSession == null) {
        continue;
      }

      if (oldestLatestSession == null ||
          latestSession.endedAt < oldestLatestSession.endedAt) {
        recommendedCourse = course;
        oldestLatestSession = latestSession;
      }
    }

    return recommendedCourse;
  }
}
