import 'package:flutter/material.dart';

import '../../../core/db/app_db.dart';
import '../../courses/data/course.dart';
import '../data/timetable_block.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  static const List<String> _weekdayLabels = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  bool _isLoading = true;
  List<Course> _courses = const [];
  List<TimetableBlock> _blocks = const [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _courseNameForBlock(TimetableBlock block) {
    for (final course in _courses) {
      if (course.id == block.courseId) {
        return course.name;
      }
    }

    return 'Unknown course';
  }

  String _weekdayLabel(int weekday) {
    if (weekday < 1 || weekday > _weekdayLabels.length) {
      return 'Unknown day';
    }

    return _weekdayLabels[weekday - 1];
  }

  String _formatMinutes(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final paddedHours = hours.toString().padLeft(2, '0');
    final paddedMinutes = minutes.toString().padLeft(2, '0');
    return '$paddedHours:$paddedMinutes';
  }

  String _formatTimeRange(TimetableBlock block) {
    return '${_formatMinutes(block.startMinutes)} - ${_formatMinutes(block.endMinutes)}';
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final courses = await AppDb.instance.getCourses();
    final blocks = await AppDb.instance.getTimetableBlocks();

    if (!mounted) {
      return;
    }

    setState(() {
      _courses = courses;
      _blocks = blocks;
      _isLoading = false;
    });
  }

  Future<void> _showAddBlockDialog() async {
    if (_courses.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Add timetable block'),
            content: const Text(
              'Create a course first before adding a timetable block.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    final didSave = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _AddTimetableBlockScreen(
          courses: _courses,
          weekdayLabels: _weekdayLabels,
        ),
      ),
    );

    if (didSave == true) {
      await _loadData();
    }
  }

  Future<void> _confirmDelete(TimetableBlock block) async {
    final blockId = block.id;
    if (blockId == null) {
      return;
    }

    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Delete timetable block?'),
              content: Text(
                'Delete ${_courseNameForBlock(block)} on ${_weekdayLabel(block.weekday)} at ${_formatTimeRange(block)}?',
              ),
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

    await AppDb.instance.deleteTimetableBlock(blockId);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Timetable')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBlockDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _blocks.isEmpty
          ? const Center(child: Text('No timetable blocks yet'))
          : ListView.builder(
              itemCount: _blocks.length,
              itemBuilder: (context, index) {
                final block = _blocks[index];
                return ListTile(
                  title: Text(_courseNameForBlock(block)),
                  subtitle: Text(
                    '${_weekdayLabel(block.weekday)} • ${_formatTimeRange(block)}',
                  ),
                  onLongPress: () => _confirmDelete(block),
                );
              },
            ),
    );
  }
}

class _AddTimetableBlockScreen extends StatefulWidget {
  const _AddTimetableBlockScreen({
    required this.courses,
    required this.weekdayLabels,
  });

  final List<Course> courses;
  final List<String> weekdayLabels;

  @override
  State<_AddTimetableBlockScreen> createState() =>
      _AddTimetableBlockScreenState();
}

class _AddTimetableBlockScreenState extends State<_AddTimetableBlockScreen> {
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late int? _selectedCourseId = widget.courses.first.id;
  int? _selectedWeekday = 1;

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  int? _parseTime(String value) {
    final match = RegExp(
      r'^([01]\d|2[0-3]):([0-5]\d)$',
    ).firstMatch(value.trim());
    if (match == null) {
      return null;
    }

    final hours = int.parse(match.group(1)!);
    final minutes = int.parse(match.group(2)!);
    return (hours * 60) + minutes;
  }

  Future<void> _saveBlock() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _selectedCourseId == null || _selectedWeekday == null) {
      return;
    }

    final startMinutes = _parseTime(_startController.text)!;
    final endMinutes = _parseTime(_endController.text)!;

    await AppDb.instance.insertTimetableBlock(
      courseId: _selectedCourseId!,
      weekday: _selectedWeekday!,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add timetable block'),
        actions: [
          TextButton(
            onPressed: () async {
              await _saveBlock();
            },
            child: const Text('Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _selectedCourseId,
                  decoration: const InputDecoration(labelText: 'Course'),
                  items: widget.courses
                      .where((course) => course.id != null)
                      .map((course) {
                        return DropdownMenuItem<int>(
                          value: course.id!,
                          child: Text(course.name),
                        );
                      })
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCourseId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please choose a course';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _selectedWeekday,
                  decoration: const InputDecoration(labelText: 'Weekday'),
                  items: List.generate(widget.weekdayLabels.length, (index) {
                    return DropdownMenuItem<int>(
                      value: index + 1,
                      child: Text(widget.weekdayLabels[index]),
                    );
                  }),
                  onChanged: (value) {
                    setState(() {
                      _selectedWeekday = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please choose a weekday';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _startController,
                  decoration: const InputDecoration(
                    labelText: 'Start time',
                    hintText: '08:30',
                  ),
                  keyboardType: TextInputType.datetime,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (_parseTime(value ?? '') == null) {
                      return 'Enter a valid time as HH:MM';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _endController,
                  decoration: const InputDecoration(
                    labelText: 'End time',
                    hintText: '10:00',
                  ),
                  keyboardType: TextInputType.datetime,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) async {
                    await _saveBlock();
                  },
                  validator: (value) {
                    final endMinutes = _parseTime(value ?? '');
                    if (endMinutes == null) {
                      return 'Enter a valid time as HH:MM';
                    }

                    final startMinutes = _parseTime(_startController.text);
                    if (startMinutes != null && endMinutes <= startMinutes) {
                      return 'End time must be after start time';
                    }

                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
