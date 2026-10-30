import 'package:flutter/material.dart';
import '../app_store.dart';
import '../ui.dart';

class RoomsPage extends StatelessWidget {
  const RoomsPage({super.key, required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) => _CatalogManager(store: store, courses: false);
}

class CoursesPage extends StatelessWidget {
  const CoursesPage({super.key, required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) => _CatalogManager(store: store, courses: true);
}

class _CatalogManager extends StatelessWidget {
  const _CatalogManager({required this.store, required this.courses});
  final AppStore store;
  final bool courses;

  String get _singular => courses ? 'curso' : 'espaço';

  Future<String?> _askName(BuildContext context, {String? oldName}) async {
    var updatedName = oldName ?? '';
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(oldName == null ? 'Adicionar $_singular' : 'Renomear $_singular'),
        content: TextFormField(
          initialValue: oldName,
          autofocus: true,
          maxLength: 70,
          decoration: fieldDecoration(courses ? 'Nome do curso' : 'Nome da sala ou laboratório'),
          textCapitalization: TextCapitalization.words,
          onChanged: (value) => updatedName = value,
          onFieldSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, updatedName), child: const Text('Salvar')),
        ],
      ),
    );
    return result;
  }

  Future<void> _add(BuildContext context) async {
    final value = await _askName(context);
    if (value == null) return;
    try {
      if (courses) {
        await store.addCourse(value);
      } else {
        await store.addRoom(value);
      }
      if (context.mounted) showInfo(context, 'Cadastro realizado.');
    } on AppMessage catch (error) {
      if (context.mounted) showInfo(context, error.message);
    }
  }

  Future<void> _edit(BuildContext context, String oldName) async {
    final value = await _askName(context, oldName: oldName);
    if (value == null) return;
    try {
      if (courses) {
        await store.renameCourse(oldName, value);
      } else {
        await store.renameRoom(oldName, value);
      }
      if (context.mounted) showInfo(context, 'Nome atualizado.');
    } on AppMessage catch (error) {
      if (context.mounted) showInfo(context, error.message);
    }
  }

  Future<void> _delete(BuildContext context, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remover $_singular?'),
        content: Text('Deseja remover "$name"? Registros associados podem impedir a exclusão.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Remover')),
        ],
      ),
    ) ?? false;
    if (!confirmed) return;
    try {
      if (courses) {
        await store.removeCourse(name);
      } else {
        await store.removeRoom(name);
      }
      if (context.mounted) showInfo(context, 'Removido com sucesso.');
    } on AppMessage catch (error) {
      if (context.mounted) showInfo(context, error.message);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, child) => ModuleLayout(
      title: courses ? 'Gerenciar cursos' : 'Gerenciar espaços',
      subtitle: courses
          ? 'Somente o líder pode cadastrar ou mudar cursos. Alunos e avisos acompanham a mudança de nome.'
          : 'Somente o líder pode cadastrar ou alterar salas. As reservas acompanham as mudanças de nome.',
      action: store.isLeader ? PrimaryAction(
        label: courses ? 'Adicionar curso' : 'Adicionar sala ou laboratório',
        icon: Icons.add,
        onPressed: () => _add(context),
      ) : null,
      body: Column(children: [
        for (final item in (courses ? store.allCourses : store.rooms)) ...[
          SoftCard(child: Row(children: [
            Icon(courses ? Icons.school_outlined : Icons.meeting_room_outlined),
            const SizedBox(width: 14),
            Expanded(child: Text(item, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
            if (store.isLeader) ...[
              IconButton(tooltip: 'Renomear', onPressed: () => _edit(context, item), icon: const Icon(Icons.edit_outlined)),
              IconButton(tooltip: 'Remover', onPressed: () => _delete(context, item), icon: const Icon(Icons.delete_outline)),
            ],
          ])),
          const SizedBox(height: 12),
        ],
      ]),
    ),
  );
}
