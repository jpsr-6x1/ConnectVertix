import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../app_store.dart';
import '../theme.dart';
import '../ui.dart';

enum EntryKind { reservation, notice, found, ride, event }

class EntryEditorPage extends StatefulWidget {
  const EntryEditorPage({super.key, required this.store, required this.kind});
  final AppStore store;
  final EntryKind kind;
  @override
  State<EntryEditorPage> createState() => _EntryEditorPageState();
}

class _EntryEditorPageState extends State<EntryEditorPage> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _destination = TextEditingController();
  final _contact = TextEditingController();
  final _vehicleDescription = TextEditingController();
  final _note = TextEditingController();
  bool _saving = false;
  bool _pickingImage = false;
  String? _photoBase64;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 19, minute: 30);
  TimeOfDay _endTime = const TimeOfDay(hour: 20, minute: 30);
  String? _room;
  String _targetCourse = '__todos__';
  String _origin = 'Complexo';
  int _seats = 1;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    _destination.dispose();
    _contact.dispose();
    _vehicleDescription.dispose();
    _note.dispose();
    super.dispose();
  }

  String get _heading => switch (widget.kind) {
    EntryKind.reservation => 'Nova reserva',
    EntryKind.notice => 'Publicar aviso',
    EntryKind.found => 'Registrar item encontrado',
    EntryKind.ride => 'Oferecer carona',
    EntryKind.event => 'Novo evento',
  };

  String _timeString(TimeOfDay value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: start,
      lastDate: start.add(const Duration(days: 730)),
      locale: const Locale('pt', 'BR'),
    );
    if (selected != null) setState(() => _date = selected);
  }

  Future<void> _pickTime({bool end = false}) async {
    final result = await showTimePicker(
      context: context,
      initialTime: end ? _endTime : _time,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (result != null) {
      setState(() {
        if (end) {
          _endTime = result;
        } else {
          _time = result;
        }
      });
    }
  }

  int _minutes(TimeOfDay value) => value.hour * 60 + value.minute;

  Future<void> _pickPhoto() async {
    setState(() => _pickingImage = true);
    try {
      // Compatível com Android e navegador: não utiliza dart:io.
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 960,
        maxHeight: 960,
        imageQuality: 65,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 8 * 1024 * 1024) {
        throw const AppMessage('Escolha uma imagem menor que 8 MB.');
      }
      final decoded = img.decodeImage(bytes);
      if (decoded == null) throw const AppMessage('Arquivo de imagem não reconhecido.');
      final resized = decoded.width > 720 || decoded.height > 720
          ? img.copyResize(decoded, width: decoded.width >= decoded.height ? 720 : null,
              height: decoded.height > decoded.width ? 720 : null)
          : decoded;
      final compressed = img.encodeJpg(resized, quality: 55);
      if (compressed.length > 220 * 1024) {
        throw const AppMessage('A foto ainda é grande demais. Escolha uma imagem mais simples.');
      }
      if (mounted) setState(() => _photoBase64 = base64Encode(compressed));
    } on AppMessage catch (error) {
      if (mounted) showInfo(context, error.message);
    } catch (_) {
      if (mounted) showInfo(context, 'Não foi possível abrir essa imagem. Tente outra foto.');
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      switch (widget.kind) {
        case EntryKind.reservation:
          await widget.store.addReservation(
            room: _room ?? widget.store.rooms.first,
            date: _date,
            startMinutes: _minutes(_time),
            endMinutes: _minutes(_endTime),
            note: _note.text,
          );
          break;
        case EntryKind.notice:
          await widget.store.addNotice(
            _title.text, _description.text,
            targetCourse: _targetCourse == '__todos__' ? null : _targetCourse,
          );
          break;
        case EntryKind.found:
          await widget.store.addFoundItem(
            _title.text, _description.text, _location.text,
            imageBase64: _photoBase64,
          );
          break;
        case EntryKind.ride:
          await widget.store.addRide(
            origin: _origin,
            destination: _destination.text,
            date: _date,
            time: _timeString(_time),
            seats: _seats,
            meetingPoint: _location.text,
            contact: _contact.text,
            vehicleDescription: _vehicleDescription.text,
          );
          break;
        case EntryKind.event:
          await widget.store.addEvent(
            title: _title.text,
            description: _description.text,
            date: _date,
            time: _timeString(_time),
            location: _location.text,
          );
          break;
      }
      if (mounted) Navigator.pop(context, true);
    } on AppMessage catch (e) {
      if (mounted) showInfo(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _input(TextEditingController controller, String label, {int maxLines = 1, String? hint, bool isRequired = true}) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        textCapitalization: TextCapitalization.sentences,
        decoration: fieldDecoration(label, hint: hint),
        validator: isRequired ? requiredField : null,
      );

  Widget _dateField() => OutlinedButton.icon(
        onPressed: _pickDate,
        icon: const Icon(Icons.calendar_today_outlined),
        label: Text('Data: ${formatDate(_date)}'),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          minimumSize: const Size(0, 54),
        ),
      );

  Widget _timeField(String title, TimeOfDay value, {bool end = false}) => OutlinedButton.icon(
        onPressed: () => _pickTime(end: end),
        icon: const Icon(Icons.access_time_outlined),
        label: Text('$title: ${_timeString(value)}'),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          minimumSize: const Size(0, 54),
        ),
      );

  Widget _formFields() {
    switch (widget.kind) {
      case EntryKind.reservation:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          DropdownButtonFormField<String>(
            value: _room ?? widget.store.rooms.first,
            isExpanded: true,
            decoration: fieldDecoration('Espaço'),
            items: [for (final room in widget.store.rooms) DropdownMenuItem(value: room, child: Text(room, overflow: TextOverflow.ellipsis))],
            onChanged: (value) { if (value != null) setState(() => _room = value); },
          ),
          const SizedBox(height: 14),
          _dateField(),
          const SizedBox(height: 14),
          _timeField('Início', _time),
          const SizedBox(height: 14),
          _timeField('Término', _endTime, end: true),
          const SizedBox(height: 14),
          _input(_note, 'Observação (opcional)', isRequired: false, hint: 'Ex.: aula de programação'),
          const SizedBox(height: 10),
          Text('O sistema impede reservas sobrepostas para o mesmo espaço.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
        ]);
      case EntryKind.notice:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          DropdownButtonFormField<String>(
            value: _targetCourse,
            isExpanded: true,
            decoration: fieldDecoration('Destinatários do aviso'),
            items: [
              const DropdownMenuItem(value: '__todos__', child: Text('Todos os cursos')),
              for (final course in widget.store.allCourses)
                DropdownMenuItem(value: course, child: Text(course, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _targetCourse = value);
            },
          ),
          const SizedBox(height: 14),
          _input(_title, 'Título do aviso'),
          const SizedBox(height: 14),
          _input(_description, 'Mensagem para os alunos', maxLines: 5),
        ]);
      case EntryKind.found:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          OutlinedButton.icon(
            onPressed: _pickingImage ? null : _pickPhoto,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(_photoBase64 == null ? 'Adicionar foto do objeto (opcional)' : 'Trocar foto'),
          ),
          if (_photoBase64 != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.memory(base64Decode(_photoBase64!), height: 190, fit: BoxFit.cover),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _photoBase64 = null),
              icon: const Icon(Icons.close),
              label: const Text('Remover foto'),
            ),
          ],
          const SizedBox(height: 14),
          _input(_title, 'Item encontrado', hint: 'Ex.: garrafa de água'),
          const SizedBox(height: 14),
          _input(_description, 'Descrição', hint: 'Ex.: garrafa preta com adesivos', maxLines: 3),
          const SizedBox(height: 14),
          _input(_location, 'Onde o item foi deixado?', hint: 'Ex.: recepção do Complexo'),
        ]);
      case EntryKind.ride:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          DropdownButtonFormField<String>(
            value: _origin,
            decoration: fieldDecoration('Saindo de'),
            items: const [
              DropdownMenuItem(value: 'Complexo', child: Text('Complexo')),
              DropdownMenuItem(value: 'Centro', child: Text('Centro')),
            ],
            onChanged: (value) { if (value != null) setState(() => _origin = value); },
          ),
          const SizedBox(height: 14),
          _input(_destination, 'Destino', hint: 'Ex.: Praça central, Matipó'),
          const SizedBox(height: 14),
          _dateField(),
          const SizedBox(height: 14),
          _timeField('Saída', _time),
          const SizedBox(height: 14),
          DropdownButtonFormField<int>(
            value: _seats,
            decoration: fieldDecoration('Vagas oferecidas'),
            items: [for (var n = 1; n <= 4; n++) DropdownMenuItem(value: n, child: Text('$n vaga${n > 1 ? 's' : ''}'))],
            onChanged: (value) { if (value != null) setState(() => _seats = value); },
          ),
          const SizedBox(height: 14),
          _input(_location, 'Ponto público de encontro', hint: 'Ex.: entrada principal do campus'),
          const SizedBox(height: 14),
          _input(_vehicleDescription, 'Descrição do carro (obrigatória)',
            hint: 'Ex.: carro branco, modelo Onix', maxLines: 2),
          const SizedBox(height: 14),
          _input(_contact, 'Contato do motorista (opcional)',
            hint: 'Ex.: WhatsApp ou outra forma de contato', isRequired: false),
          const SizedBox(height: 10),
          Text('O contato informado será exibido no anúncio para quem estiver conectado. Compartilhe-o apenas se desejar. Combine o encontro em local público.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
        ]);
      case EntryKind.event:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _input(_title, 'Nome do evento'),
          const SizedBox(height: 14),
          _input(_description, 'Descrição', maxLines: 4),
          const SizedBox(height: 14),
          _input(_location, 'Local', hint: 'Ex.: auditório do Complexo'),
          const SizedBox(height: 14),
          _dateField(),
          const SizedBox(height: 14),
          _timeField('Horário', _time),
        ]);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(_heading),
          leading: IconButton(
            tooltip: 'Voltar',
            icon: const Icon(Icons.arrow_back),
            onPressed: () { Navigator.of(context).maybePop(); },
          ),
        ),
        body: SafeArea(child: CenterColumn(maxWidth: 680, child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
          children: [
            Text(_heading, style: TextStyle(fontSize: 29, fontWeight: FontWeight.w700)),
            const SizedBox(height: 7),
            Text('Preencha os dados abaixo para concluir.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 22),
            Form(key: _form, child: SoftCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _formFields(),
              const SizedBox(height: 25),
              ElevatedButton.icon(
                onPressed: (_saving || _pickingImage) ? null : _save,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(_saving ? 'Salvando...' : 'Salvar'),
              ),
            ]))),
          ],
        ))),
      );
}
