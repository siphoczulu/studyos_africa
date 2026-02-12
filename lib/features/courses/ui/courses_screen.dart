import 'package:flutter/material.dart';

import '../../../core/db/app_db.dart';
import '../data/course.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  bool _isLoading = true;
  List<Course> _courses = const [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
    });

    final courses = await AppDb.instance.getCourses();

    if (!mounted) {
      return;
    }

    setState(() {
      _courses = courses;
      _isLoading = false;
    });
  }

  Future<void> _showAddCourseDialog() async {
    final controller = TextEditingController();
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add course'),
              content: TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Course name',
                  errorText: errorText,
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) async {
                  final name = controller.text.trim();
                  if (name.isEmpty) {
                    setDialogState(() {
                      errorText = 'Please enter a course name';
                    });
                    return;
                  }

                  await AppDb.instance.insertCourse(name);
                  if (!mounted) {
                    return;
                  }
                  Navigator.of(context).pop();
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
                    final name = controller.text.trim();
                    if (name.isEmpty) {
                      setDialogState(() {
                        errorText = 'Please enter a course name';
                      });
                      return;
                    }

                    await AppDb.instance.insertCourse(name);
                    if (!mounted) {
                      return;
                    }
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    await _loadCourses();
  }

  Future<void> _confirmDelete(Course course) async {
    final shouldDelete = await showDialog<bool>(
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
        actions: [
          IconButton(
            onPressed: _showAddCourseDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Add course',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _courses.isEmpty
              ? const Center(child: Text('No courses yet'))
              : ListView.builder(
                  itemCount: _courses.length,
                  itemBuilder: (context, index) {
                    final course = _courses[index];
                    return ListTile(
                      title: Text(course.name),
                      onLongPress: () => _confirmDelete(course),
                    );
                  },
                ),
    );
  }
}
