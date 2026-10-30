import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'courses.dart';

class AppMessage implements Exception {
  const AppMessage(this.message);
  final String message;
  @override
  String toString() => message;
}

class AppStore extends ChangeNotifier {
  AppStore._(this._prefs);

  // APENAS PARA DEMONSTRAÇÃO. Credenciais em código/localStorage não são
  // seguras para uma aplicação real; use autenticação e regras no servidor.
  static const leaderName = 'lider';
  static const leaderPassword = 'Vertix@2026';
  static const _key = 'connectvertix_web_demo_v1';
  final SharedPreferences _prefs;

  final List<UserAccount> users = [];
  final List<Reservation> reservations = [];
  final List<Notice> notices = [];
  final List<FoundItem> foundItems = [];
  final List<RideOffer> rides = [];
  final List<CampusEvent> events = [];
  final List<String> rooms = [];
  final List<String> courses = [];
  bool _darkMode = false;
  bool get darkMode => _darkMode;

  static const defaultRooms = <String>[
    'Laboratório de Informática 1',
    'Laboratório de Informática 2',
    'Sala 101',
    'Sala 102',
    'Auditório',
  ];
  String? _sessionId;
  int _sequence = 0;
  bool _demoSeeded = false;

  static Future<AppStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    final store = AppStore._(prefs);
    final content = prefs.getString(_key);
    if (content != null) {
      try {
        final data = Map<String, dynamic>.from(jsonDecode(content) as Map);
        for (final entry in data['users'] as List<dynamic>? ?? []) {
          store.users.add(UserAccount.fromJson(Map<String, dynamic>.from(entry as Map)));
        }
        for (final entry in data['reservations'] as List<dynamic>? ?? []) {
          store.reservations.add(Reservation.fromJson(Map<String, dynamic>.from(entry as Map)));
        }
        for (final entry in data['notices'] as List<dynamic>? ?? []) {
          store.notices.add(Notice.fromJson(Map<String, dynamic>.from(entry as Map)));
        }
        for (final entry in data['foundItems'] as List<dynamic>? ?? []) {
          store.foundItems.add(FoundItem.fromJson(Map<String, dynamic>.from(entry as Map)));
        }
        for (final entry in data['rides'] as List<dynamic>? ?? []) {
          store.rides.add(RideOffer.fromJson(Map<String, dynamic>.from(entry as Map)));
        }
        for (final entry in data['events'] as List<dynamic>? ?? []) {
          store.events.add(CampusEvent.fromJson(Map<String, dynamic>.from(entry as Map)));
        }
        store._sessionId = data['sessionId'] as String?;
        store._sequence = data['sequence'] as int? ?? 0;
        store._demoSeeded = data['demoSeeded'] == true;
        store._darkMode = data['darkMode'] == true;
        final storedRooms = data['rooms'] as List<dynamic>?;
        if (storedRooms != null) {
          store.rooms.addAll(storedRooms.map((room) => room as String));
        }
        final savedCourses = data['courses'] as List<dynamic>?;
        if (savedCourses != null) {
          store.courses.addAll(savedCourses.map((course) => course as String));
        } else {
          // Migração dos cadastros e avisos das versões anteriores.
          store.courses.addAll(campusCourses);
          for (final user in store.users) {
            if (user.course != null && !store.courses.contains(user.course)) {
              store.courses.add(user.course!);
            }
          }
          for (final notice in store.notices) {
            if (notice.targetCourse != null && !store.courses.contains(notice.targetCourse)) {
              store.courses.add(notice.targetCourse!);
            }
          }
        }
      } catch (error) {
        // Dados locais inválidos são ignorados na versão demonstrativa.
        store.users.clear();
        store.reservations.clear();
        store.notices.clear();
        store.foundItems.clear();
        store.rides.clear();
        store.events.clear();
        store._sessionId = null;
        store._sequence = 0;
        store._demoSeeded = false;
        store._darkMode = false;
        store.rooms.clear();
        store.courses.clear();
      }
    }
    if (store.rooms.isEmpty) store.rooms.addAll(defaultRooms);
    if (store.courses.isEmpty) store.courses.addAll(campusCourses);
    store._seed();
    await store._save();
    return store;
  }

  UserAccount? get currentUser {
    for (final user in users) {
      if (user.id == _sessionId) return user;
    }
    return null;
  }

  bool get canManage => currentUser?.canManage ?? false;
  bool get isLeader => currentUser?.isLeader ?? false;
  List<UserAccount> get pendingRequests =>
      users.where((u) => u.requestStatus == 'pendente').toList();
  List<String> get allCourses => List<String>.from(courses)..sort();

  List<String> passengerNames(RideOffer ride) => [
    for (final id in ride.passengerIds)
      for (final user in users)
        if (user.id == id) user.name,
  ];

  List<FoundItem> get availableFoundItems =>
      foundItems.where((item) => item.isAvailable).toList();

  List<Notice> get visibleNotices {
    final user = currentUser;
    if (user == null) return [];
    if (user.canManage) return List<Notice>.from(notices);
    return notices.where((notice) =>
      notice.targetCourse == null ||
      notice.targetCourse == user.course
    ).toList();
  }

  List<UserAccount> get professors =>
      users.where((u) => u.role == 'professor').toList();

  String _id() => '${DateTime.now().microsecondsSinceEpoch}_${++_sequence}';

  void _seed() {
    // A conta líder existe sempre e não pode ser criada por cadastro comum.
    users.removeWhere((u) => u.id == 'conta_lider');
    users.insert(0, UserAccount(
      id: 'conta_lider',
      name: leaderName,
      password: leaderPassword,
      role: 'lider',
    ));
    if (!_demoSeeded && events.isEmpty && notices.isEmpty && reservations.isEmpty) {
      events.add(CampusEvent(
        id: 'evento_exemplo',
        title: '4ª Semana da Informática',
        description: 'Palestras, apresentações e atividades acadêmicas.',
        date: DateTime(2026, 11, 11),
        time: '19:30',
        location: 'Campus Matipó',
        authorId: 'conta_lider',
      ));
      notices.addAll([
        Notice(
          id: 'aviso_exemplo_1',
          title: 'Entrega dos projetos da Feira',
          message: 'Prazo final: 30/10. Confiram as orientações da coordenação.',
          authorId: 'conta_lider',
          authorName: 'Coordenação',
          createdAt: DateTime(2026, 10, 29),
        ),
        Notice(
          id: 'aviso_exemplo_2',
          title: 'Lista dos projetos classificados',
          message: 'Divulgação prevista para 09/11.',
          authorId: 'conta_lider',
          authorName: 'Coordenação',
          createdAt: DateTime(2026, 10, 28),
        ),
      ]);
    }
    _demoSeeded = true;
  }

  Future<void> _save() async {
    await _prefs.setString(_key, jsonEncode({
      'users': users.map((u) => u.toJson()).toList(),
      'reservations': reservations.map((r) => r.toJson()).toList(),
      'notices': notices.map((n) => n.toJson()).toList(),
      'foundItems': foundItems.map((f) => f.toJson()).toList(),
      'rides': rides.map((r) => r.toJson()).toList(),
      'events': events.map((e) => e.toJson()).toList(),
      'sessionId': _sessionId,
      'sequence': _sequence,
      'demoSeeded': _demoSeeded,
      'darkMode': _darkMode,
      'rooms': rooms,
      'courses': courses,
    }));
    notifyListeners();
  }

  Future<void> register(String name, String password, {required String course}) async {
    final trimmed = name.trim();
    final selectedCourse = course.trim();
    if (!courses.contains(selectedCourse)) {
      throw const AppMessage('Selecione um dos cursos disponíveis.');
    }
    if (trimmed.length < 3) throw const AppMessage('Use um nome com pelo menos 3 caracteres.');
    if (password.length < 4) throw const AppMessage('A senha deve ter pelo menos 4 caracteres.');
    if (users.any((u) => u.name.toLowerCase() == trimmed.toLowerCase())) {
      throw const AppMessage('Esse nome já está em uso.');
    }
    final user = UserAccount(id: _id(), name: trimmed, password: password, course: selectedCourse);
    users.add(user);
    _sessionId = user.id;
    await _save();
  }

  Future<void> login(String name, String password) async {
    for (final user in users) {
      if (user.name.toLowerCase() == name.trim().toLowerCase() &&
          user.password == password) {
        _sessionId = user.id;
        await _save();
        return;
      }
    }
    throw const AppMessage('Nome ou senha incorretos.');
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    await _save();
  }

  Future<void> updateCourse(String course) async {
    final user = _requireUser();
    if (user.isLeader) throw const AppMessage('A conta líder não possui curso.');
    final value = course.trim();
    if (!courses.contains(value)) throw const AppMessage('Selecione um curso cadastrado.');
    user.course = value;
    await _save();
  }

  Future<void> renameRoom(String oldName, String newName) async {
    _requireLeader();
    final value = newName.trim();
    if (value.length < 3) throw const AppMessage('Use pelo menos 3 caracteres.');
    final index = rooms.indexOf(oldName);
    if (index < 0) throw const AppMessage('Sala não encontrada.');
    if (rooms.any((room) =>
        room.toLowerCase() == value.toLowerCase() && room != oldName)) {
      throw const AppMessage('Já existe um espaço com esse nome.');
    }
    rooms[index] = value;
    // Mantém reservas antigas ligadas ao espaço após a troca do nome.
    for (final reservation in reservations) {
      if (reservation.room == oldName) reservation.room = value;
    }
    await _save();
  }

  Future<void> addRoom(String name) async {
    _requireLeader();
    final value = name.trim();
    if (value.length < 3) throw const AppMessage('Use pelo menos 3 caracteres.');
    if (rooms.any((room) => room.toLowerCase() == value.toLowerCase())) {
      throw const AppMessage('Já existe uma sala ou laboratório com esse nome.');
    }
    rooms.add(value);
    await _save();
  }

  Future<void> removeRoom(String room) async {
    _requireLeader();
    if (!rooms.contains(room)) throw const AppMessage('Espaço não encontrado.');
    if (reservations.any((r) => r.room == room)) {
      throw const AppMessage('Esse espaço possui reservas. Exclua as reservas antes de removê-lo.');
    }
    if (rooms.length == 1) throw const AppMessage('Mantenha pelo menos um espaço.');
    rooms.remove(room);
    await _save();
  }

  Future<void> addCourse(String name) async {
    _requireLeader();
    final value = name.trim();
    if (value.length < 3) throw const AppMessage('Use pelo menos 3 caracteres.');
    if (courses.any((course) => course.toLowerCase() == value.toLowerCase())) {
      throw const AppMessage('Esse curso já está cadastrado.');
    }
    courses.add(value);
    await _save();
  }

  Future<void> renameCourse(String oldName, String newName) async {
    _requireLeader();
    final value = newName.trim();
    if (value.length < 3) throw const AppMessage('Use pelo menos 3 caracteres.');
    final index = courses.indexOf(oldName);
    if (index == -1) throw const AppMessage('Curso não encontrado.');
    if (courses.any((course) => course != oldName && course.toLowerCase() == value.toLowerCase())) {
      throw const AppMessage('Esse curso já está cadastrado.');
    }
    courses[index] = value;
    for (final user in users) {
      if (user.course == oldName) user.course = value;
    }
    for (final notice in notices) {
      if (notice.targetCourse == oldName) notice.targetCourse = value;
    }
    await _save();
  }

  Future<void> removeCourse(String course) async {
    _requireLeader();
    if (!courses.contains(course)) throw const AppMessage('Curso não encontrado.');
    if (users.any((user) => user.course == course) || notices.any((notice) => notice.targetCourse == course)) {
      throw const AppMessage('Esse curso está vinculado a alunos ou avisos. Atualize os vínculos antes de excluí-lo.');
    }
    if (courses.length == 1) throw const AppMessage('Mantenha pelo menos um curso.');
    courses.remove(course);
    await _save();
  }

  Future<void> logout() async {
    _sessionId = null;
    await _save();
  }

  UserAccount _requireUser() {
    final user = currentUser;
    if (user == null) throw const AppMessage('Entre na sua conta.');
    return user;
  }

  UserAccount _requireProfessor() {
    final user = _requireUser();
    if (!user.canManage) {
      throw const AppMessage('Apenas professores podem alterar este módulo.');
    }
    return user;
  }

  void _requireLeader() {
    if (!isLeader) throw const AppMessage('Apenas a conta líder pode aprovar professores.');
  }

  Future<void> requestProfessor() async {
    final user = _requireUser();
    if (user.canManage) return;
    if (user.requestStatus == 'pendente') {
      throw const AppMessage('Seu pedido já está aguardando análise.');
    }
    user.requestStatus = 'pendente';
    await _save();
  }

  Future<void> decideRequest(String userId, bool approve) async {
    _requireLeader();
    final matches = users.where((u) => u.id == userId && u.requestStatus == 'pendente');
    if (matches.isEmpty) throw const AppMessage('Solicitação não encontrada.');
    final user = matches.first;
    user.role = approve ? 'professor' : 'aluno';
    user.requestStatus = approve ? 'aprovada' : 'recusada';
    await _save();
  }

  Future<void> revokeProfessor(String userId) async {
    _requireLeader();
    final matches = users.where((u) => u.id == userId && u.role == 'professor');
    if (matches.isEmpty) throw const AppMessage('Professor não encontrado.');
    matches.first.role = 'aluno';
    matches.first.requestStatus = 'nenhuma';
    await _save();
  }

  Future<void> addReservation({
    required String room,
    required DateTime date,
    required int startMinutes,
    required int endMinutes,
    required String note,
  }) async {
    final author = _requireProfessor();
    if (!rooms.contains(room)) throw const AppMessage('Espaço inválido.');
    if (startMinutes >= endMinutes) throw const AppMessage('O horário final deve ser posterior ao inicial.');
    final conflict = reservations.any((r) =>
        r.room == room &&
        r.date.year == date.year &&
        r.date.month == date.month &&
        r.date.day == date.day &&
        startMinutes < r.endMinutes &&
        endMinutes > r.startMinutes);
    if (conflict) throw const AppMessage('Esta sala já está reservada nesse horário.');
    reservations.add(Reservation(
      id: _id(),
      room: room,
      date: date,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      note: note,
      authorId: author.id,
      authorName: author.name,
    ));
    await _save();
  }

  Future<void> removeReservation(String id) async {
    _requireProfessor();
    reservations.removeWhere((r) => r.id == id);
    await _save();
  }

  Future<void> addNotice(String title, String message, {String? targetCourse}) async {
    final author = _requireProfessor();
    if (targetCourse != null && targetCourse.trim().isNotEmpty && !courses.contains(targetCourse.trim())) {
      throw const AppMessage('Curso destinatário não cadastrado.');
    }
    notices.insert(0, Notice(
      id: _id(),
      title: title.trim(),
      message: message.trim(),
      authorId: author.id,
      authorName: author.name,
      createdAt: DateTime.now(),
      targetCourse: targetCourse?.trim().isEmpty == true ? null : targetCourse?.trim(),
    ));
    await _save();
  }

  Future<void> removeNotice(String id) async {
    _requireProfessor();
    notices.removeWhere((n) => n.id == id);
    await _save();
  }

  Future<void> addFoundItem(String name, String description, String location, {String? imageBase64}) async {
    final author = _requireUser();
    // Evita exceder a pequena quota de armazenamento local dos navegadores.
    final currentPhotos = foundItems.fold<int>(0, (sum, item) => sum + (item.imageBase64?.length ?? 0));
    if (currentPhotos + (imageBase64?.length ?? 0) > 1400000) {
      throw const AppMessage('Armazenamento de fotos cheio neste dispositivo. Exclua alguns itens antes de adicionar novas imagens.');
    }
    foundItems.insert(0, FoundItem(
      id: _id(),
      name: name.trim(),
      description: description.trim(),
      location: location.trim(),
      authorId: author.id,
      authorName: author.name,
      createdAt: DateTime.now(),
      imageBase64: imageBase64,
    ));
    await _save();
  }

  Future<void> confirmFoundItemRetrieved(String id, String ownerName) async {
    final user = _requireUser();
    final owner = ownerName.trim();
    if (owner.length < 2) throw const AppMessage('Informe o nome de quem retirou o objeto.');
    final matches = foundItems.where((item) => item.id == id && item.isAvailable);
    if (matches.isEmpty) throw const AppMessage('Item não disponível.');
    final item = matches.first;
    if (item.authorId != user.id && !user.isLeader) {
      throw const AppMessage('Apenas quem cadastrou ou a conta líder pode confirmar a entrega.');
    }
    item.retrievedAt = DateTime.now();
    item.retrievedByName = owner;
    item.imageBase64 = null; // a foto não ocupa espaço depois da retirada
    await _save();
  }

  Future<void> removeFoundItem(String id) async {
    final author = _requireUser();
    foundItems.removeWhere((f) => f.id == id && (f.authorId == author.id || author.isLeader));
    await _save();
  }

  Future<void> addRide({
    required String origin,
    required String destination,
    required DateTime date,
    required String time,
    required int seats,
    required String meetingPoint,
    required String vehicleDescription,
    String? contact,
  }) async {
    final author = _requireUser();
    final start = origin.trim();
    final finish = destination.trim();
    final car = vehicleDescription.trim();
    final optionalContact = contact?.trim();
    if (start != 'Centro' && start != 'Complexo') {
      throw const AppMessage('Escolha Centro ou Complexo como origem.');
    }
    if (finish.isEmpty) throw const AppMessage('Informe o destino da carona.');
    if (car.isEmpty) throw const AppMessage('Informe a descrição do carro.');
    if (meetingPoint.trim().isEmpty) throw const AppMessage('Informe o ponto de encontro.');
    if (seats < 1 || seats > 4) throw const AppMessage('Informe de 1 a 4 vagas.');
    rides.insert(0, RideOffer(
      id: _id(),
      origin: start,
      destination: finish,
      date: date,
      time: time,
      seats: seats,
      meetingPoint: meetingPoint.trim(),
      vehicleDescription: car,
      contact: optionalContact == null || optionalContact.isEmpty ? null : optionalContact,
      authorId: author.id,
      authorName: author.name,
    ));
    await _save();
  }

  Future<void> reserveRide(String rideId) async {
    final user = _requireUser();
    final matches = rides.where((ride) => ride.id == rideId);
    if (matches.isEmpty) throw const AppMessage('Carona não encontrada.');
    final ride = matches.first;
    if (ride.authorId == user.id) {
      throw const AppMessage('Você não pode reservar sua própria carona.');
    }
    if (ride.passengerIds.contains(user.id)) {
      throw const AppMessage('Você já reservou uma vaga nessa carona.');
    }
    if (ride.availableSeats <= 0) {
      throw const AppMessage('Não há vagas disponíveis.');
    }
    ride.passengerIds.add(user.id);
    await _save();
  }

  Future<void> cancelRideBooking(String rideId) async {
    final user = _requireUser();
    final matches = rides.where((ride) => ride.id == rideId);
    if (matches.isEmpty) throw const AppMessage('Carona não encontrada.');
    final ride = matches.first;
    if (!ride.passengerIds.remove(user.id)) {
      throw const AppMessage('Você não possui reserva nessa carona.');
    }
    await _save();
  }

  Future<void> removeRide(String id) async {
    final author = _requireUser();
    rides.removeWhere((r) => r.id == id && (r.authorId == author.id || author.isLeader));
    await _save();
  }

  Future<void> addEvent({
    required String title,
    required String description,
    required DateTime date,
    required String time,
    required String location,
  }) async {
    final author = _requireProfessor();
    events.add(CampusEvent(
      id: _id(),
      title: title.trim(),
      description: description.trim(),
      date: date,
      time: time,
      location: location.trim(),
      authorId: author.id,
    ));
    await _save();
  }

  Future<void> removeEvent(String id) async {
    _requireProfessor();
    events.removeWhere((e) => e.id == id);
    await _save();
  }
}
