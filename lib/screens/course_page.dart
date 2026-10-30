import 'package:flutter/material.dart';
import '../app_store.dart';
import '../ui.dart';
import 'course_selector.dart';

class CoursePage extends StatefulWidget {
  const CoursePage({super.key, required this.store});
  final AppStore store;

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  final _form = GlobalKey<FormState>();
  String? _course;
  bool _saving = false;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.store.updateCourse(_course ?? widget.store.currentUser?.course ?? '');
      if (mounted) Navigator.pop(context);
    } on AppMessage catch (error) {
      if (mounted) showInfo(context, error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => ModuleLayout(
    title: 'Meu curso',
    subtitle: 'Selecione seu curso para receber os avisos destinados à sua turma.',
    body: Form(key: _form, child: SoftCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CourseSelector(
          store: widget.store,
          initialCourse: widget.store.currentUser?.course,
          onChanged: (value) => _course = value,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: const Text('Salvar curso'),
        ),
      ],
    ))),
  );
}
