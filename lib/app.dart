import 'package:flutter/material.dart';
import 'package:studyos_africa/features/courses/ui/courses_screen.dart';

class StudyOsApp extends StatelessWidget {
  const StudyOsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: CoursesScreen(),
    );
  }
}
