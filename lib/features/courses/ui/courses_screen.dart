import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/db/app_db.dart';
import '../data/course.dart';
import '../domain/today_plan_recommender.dart';
import '../../file_library/ui/file_library_screen.dart';
import '../../study_sessions/data/study_session.dart';
import '../../timetable/ui/timetable_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  bool _isLoading = true;
  List<Course> _courses = const [];
  List<StudySession> _sessions = const [];
  final TextEditingController _courseNameController = TextEditingController();
  Course? _activeCourse;
  DateTime? _sessionStartedAt;
  Timer? _ticker;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _courseNameController.dispose();
    super.dispose();
  }

  String _formatElapsed(int elapsedSeconds) {
    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;
    final paddedMinutes = minutes.toString().padLeft(2, '0');
    final paddedSeconds = seconds.toString().padLeft(2, '0');
    return '$paddedMinutes:$paddedSeconds';
  }

  String _courseNameForSession(StudySession session) {
    for (final course in _courses) {
      if (course.id == session.courseId) {
        return course.name;
      }
    }

    return 'Unknown course';
  }

  List<StudySession> get _recentSessions => _sessions.take(5).toList();

  _TodayPlanRecommendation? get _todayPlanRecommendation {
    final recommendedCourse = TodayPlanRecommender.recommendCourse(
      courses: _courses,
      sessions: _sessions,
    );
    if (recommendedCourse == null) {
      return null;
    }

    final courseId = recommendedCourse.id;
    final hasStudySession =
        courseId != null &&
        _sessions.any((session) => session.courseId == courseId);

    return _TodayPlanRecommendation(
      course: recommendedCourse,
      subtitle: hasStudySession
          ? 'Last studied in an earlier session'
          : 'Never studied yet',
    );
  }

  void _startStudySession(Course course) {
    if (_activeCourse != null) {
      return;
    }

    _ticker?.cancel();
    final startedAt = DateTime.now();

    setState(() {
      _activeCourse = course;
      _sessionStartedAt = startedAt;
      _elapsedSeconds = 0;
    });

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _sessionStartedAt == null) {
        return;
      }

      setState(() {
        _elapsedSeconds = DateTime.now()
            .difference(_sessionStartedAt!)
            .inSeconds;
      });
    });
  }

  Future<void> _stopStudySession() async {
    final activeCourse = _activeCourse;
    final sessionStartedAt = _sessionStartedAt;
    final courseId = activeCourse?.id;

    _ticker?.cancel();
    _ticker = null;

    if (activeCourse == null || sessionStartedAt == null || courseId == null) {
      if (mounted) {
        setState(() {
          _activeCourse = null;
          _sessionStartedAt = null;
          _elapsedSeconds = 0;
        });
      }
      return;
    }

    final endedAt = DateTime.now();
    final durationSeconds = endedAt.difference(sessionStartedAt).inSeconds;

    await AppDb.instance.insertStudySession(
      courseId: courseId,
      startedAt: sessionStartedAt.millisecondsSinceEpoch,
      endedAt: endedAt.millisecondsSinceEpoch,
      durationSeconds: durationSeconds,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _activeCourse = null;
      _sessionStartedAt = null;
      _elapsedSeconds = 0;
    });

    await _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
    });

    final courses = await AppDb.instance.getCourses();
    final sessions = await AppDb.instance.getStudySessions();

    if (!mounted) {
      return;
    }

    setState(() {
      _courses = courses;
      _sessions = sessions;
      _isLoading = false;
    });
  }

  Future<void> _showAddCourseDialog() async {
    _courseNameController.clear();
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (context) {
        Future<void> saveCourse(VoidCallback showValidationError) async {
          final name = _courseNameController.text.trim();
          if (name.isEmpty) {
            showValidationError();
            return;
          }

          await AppDb.instance.insertCourse(name);
          if (!mounted) {
            return;
          }

          Navigator.of(this.context).pop();
        }

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add course'),
              content: TextField(
                controller: _courseNameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Course name',
                  errorText: errorText,
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) async {
                  await saveCourse(() {
                    setDialogState(() {
                      errorText = 'Please enter a course name';
                    });
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    await saveCourse(() {
                      setDialogState(() {
                        errorText = 'Please enter a course name';
                      });
                    });
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    _courseNameController.clear();
    await _loadCourses();
  }

  Future<void> _confirmDelete(Course course) async {
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Delete course?'),
              content: Text('Delete "${course.name}"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldDelete) {
      return;
    }

    final courseId = course.id;
    if (courseId == null) {
      return;
    }

    await AppDb.instance.deleteCourse(courseId);
    await _loadCourses();
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveSession = _activeCourse != null;
    final hasCourses = _courses.isNotEmpty;
    final todayPlan = _todayPlanRecommendation;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const FileLibraryScreen(),
                ),
              );
            },
            icon: const Icon(Icons.folder),
            tooltip: 'File library',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const TimetableScreen(),
                ),
              );
            },
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Weekly timetable',
          ),
          IconButton(
            onPressed: _showAddCourseDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Add course',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              children: [
                if (hasActiveSession)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _activeCourse!.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Elapsed: ${_formatElapsed(_elapsedSeconds)}',
                                  ),
                                ],
                              ),
                            ),
                            FilledButton(
                              onPressed: _stopStudySession,
                              child: const Text('Stop'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (todayPlan != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: const Text('Today Plan'),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                todayPlan.course.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(todayPlan.subtitle),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Recent Sessions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                if (_recentSessions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('No study sessions yet'),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      children: _recentSessions.map((session) {
                        return ListTile(
                          dense: true,
                          title: Text(_courseNameForSession(session)),
                          subtitle: Text(
                            _formatElapsed(session.durationSeconds),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                if (hasCourses)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _courses.length,
                    itemBuilder: (context, index) {
                      final course = _courses[index];
                      return ListTile(
                        title: Text(course.name),
                        trailing: IconButton(
                          onPressed: hasActiveSession
                              ? null
                              : () => _startStudySession(course),
                          icon: const Icon(Icons.play_arrow),
                          tooltip: 'Start study session',
                        ),
                        onLongPress: hasActiveSession
                            ? null
                            : () => _confirmDelete(course),
                      );
                    },
                  )
                else
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text('No courses yet'),
                  ),
              ],
            ),
    );
  }
}

class _TodayPlanRecommendation {
  const _TodayPlanRecommendation({
    required this.course,
    required this.subtitle,
  });

  final Course course;
  final String subtitle;
}
