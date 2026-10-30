import 'package:flutter/material.dart';
import '../app_store.dart';
import '../ui.dart';

/// Cursos cadastrados e administrados somente pela conta líder.
class CourseSelector extends StatefulWidget {
  const CourseSelector({super.key, required this.store, required this.onChanged, this.initialCourse});
  final AppStore store;
  final ValueChanged<String?> onChanged;
  final String? initialCourse;

  @override
  State<CourseSelector> createState() => _CourseSelectorState();
}

class _CourseSelectorState extends State<CourseSelector> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialCourse;
  }

  @override
  Widget build(BuildContext context) {
    final courses = widget.store.allCourses;
    final value = courses.contains(_selected) ? _selected : null;
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: fieldDecoration('Curso'),
      hint: const Text('Selecione seu curso'),
      items: [
        for (final course in courses)
          DropdownMenuItem(value: course, child: Text(course, overflow: TextOverflow.ellipsis)),
      ],
      onChanged: (course) {
        setState(() => _selected = course);
        widget.onChanged(course);
      },
      validator: (value) => value == null ? 'Selecione seu curso.' : null,
    );
  }
}
