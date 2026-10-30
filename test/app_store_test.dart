import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectvertix/app_store.dart';
import 'package:connectvertix/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('aluno escolhe curso e precisa de aprovação para publicar', () async {
    final store = await AppStore.load();
    await store.register('Ana', '1234', course: 'Ciência da Computação');
    expect(store.currentUser!.course, 'Ciência da Computação');
    expect(store.canManage, isFalse);
    await store.requestProfessor();
    expect(store.pendingRequests.single.name, 'Ana');
    await store.logout();
    await store.login(AppStore.leaderName, AppStore.leaderPassword);
    await store.decideRequest(store.pendingRequests.single.id, true);
    await store.logout();
    await store.login('Ana', '1234');
    expect(store.canManage, isTrue);
  });

  test('avisos segmentados aparecem só no curso selecionado', () async {
    final store = await AppStore.load();
    await store.register('Ana', '1234', course: 'Ciência da Computação');
    await store.logout();
    await store.register('Bruno', '1234', course: 'Direito');
    await store.logout();
    await store.login(AppStore.leaderName, AppStore.leaderPassword);
    await store.addNotice('Aviso específico', 'Reunião de programação',
        targetCourse: 'Ciência da Computação');
    await store.addNotice('Aviso geral', 'Evento para todos');
    await store.logout();

    await store.login('Ana', '1234');
    expect(store.visibleNotices.map((notice) => notice.title),
        containsAll(['Aviso específico', 'Aviso geral']));
    await store.logout();
    await store.login('Bruno', '1234');
    expect(store.visibleNotices.map((notice) => notice.title),
        isNot(contains('Aviso específico')));
    expect(store.visibleNotices.map((notice) => notice.title),
        contains('Aviso geral'));
  });

  test('sala renomeada preserva reservas e impede conflitos', () async {
    final store = await AppStore.load();
    await store.login(AppStore.leaderName, AppStore.leaderPassword);
    await store.addReservation(
      room: 'Laboratório de Informática 1',
      date: DateTime(2026, 11, 18),
      startMinutes: 19 * 60,
      endMinutes: 20 * 60,
      note: 'Aula 1',
    );
    await store.renameRoom('Laboratório de Informática 1', 'Laboratório de Redes');
    expect(store.rooms, contains('Laboratório de Redes'));
    expect(store.reservations.single.room, 'Laboratório de Redes');
    await expectLater(
      store.addReservation(
        room: 'Laboratório de Redes',
        date: DateTime(2026, 11, 18),
        startMinutes: 19 * 60 + 30,
        endMinutes: 21 * 60,
        note: 'Aula 2',
      ),
      throwsA(isA<AppMessage>()),
    );
    await expectLater(
      store.renameRoom('Laboratório de Redes', 'Sala 101'),
      throwsA(isA<AppMessage>()),
    );
  });

  test('uma vaga de carona não pode ser reservada duas vezes', () async {
    final store = await AppStore.load();
    await store.register('Motorista', '1234', course: 'Direito');
    await store.addRide(
      origin: 'Complexo', destination: 'Centro',
      date: DateTime(2026, 11, 18), time: '18:00',
      seats: 1, meetingPoint: 'Portaria do campus', vehicleDescription: 'Fiat Uno prata',
    );
    final ride = store.rides.single;
    expect(ride.availableSeats, 1);
    await expectLater(store.reserveRide(ride.id), throwsA(isA<AppMessage>()));
    await store.logout();

    await store.register('Bruno', '1234', course: 'Direito');
    await store.reserveRide(ride.id);
    expect(ride.availableSeats, 0);
    await expectLater(store.reserveRide(ride.id), throwsA(isA<AppMessage>()));
    await store.logout();

    await store.register('Carla', '1234', course: 'Enfermagem');
    await expectLater(store.reserveRide(ride.id), throwsA(isA<AppMessage>()));
    await store.logout();
    await store.login('Bruno', '1234');
    await store.cancelRideBooking(ride.id);
    expect(ride.availableSeats, 1);
    await store.logout();
    await store.login('Carla', '1234');
    await store.reserveRide(ride.id);
    expect(ride.availableSeats, 0);
  });

  test('tema, curso e reservas de vagas persistem ao recarregar', () async {
    var store = await AppStore.load();
    await store.register('Motorista', '1234', course: 'Direito');
    await store.addRide(
      origin: 'Centro', destination: 'Complexo',
      date: DateTime(2026, 11, 20), time: '08:00', seats: 2,
      meetingPoint: 'Entrada do Centro', vehicleDescription: 'Gol branco',
    );
    await store.logout();
    await store.register('Ana', '1234', course: 'Direito');
    await store.reserveRide(store.rides.single.id);
    await store.updateCourse('Ciência da Computação');
    await store.setDarkMode(true);

    store = await AppStore.load();
    expect(store.darkMode, isTrue);
    expect(store.currentUser!.course, 'Ciência da Computação');
    expect(store.rides.single.availableSeats, 1);
  });

  test('líder gerencia cursos e o novo nome acompanha alunos e avisos', () async {
    final store = await AppStore.load();
    await store.login(AppStore.leaderName, AppStore.leaderPassword);
    await store.addCourse('Design Digital');
    await store.logout();
    await store.register('Luiza', '1234', course: 'Design Digital');
    await expectLater(store.addCourse('Teste'), throwsA(isA<AppMessage>()));
    await store.logout();
    await store.login(AppStore.leaderName, AppStore.leaderPassword);
    await store.addNotice('Reunião', 'Sala 101', targetCourse: 'Design Digital');
    await store.renameCourse('Design Digital', 'Design e Comunicação');
    expect(store.allCourses, contains('Design e Comunicação'));
    expect(store.allCourses, isNot(contains('Design Digital')));
    expect(store.users.firstWhere((u) => u.name == 'Luiza').course, 'Design e Comunicação');
    expect(store.notices.first.targetCourse, 'Design e Comunicação');
    await expectLater(store.renameCourse('Design e Comunicação', 'Direito'), throwsA(isA<AppMessage>()));
    await expectLater(store.removeCourse('Design e Comunicação'), throwsA(isA<AppMessage>()));
    await store.logout();
    await store.login('Luiza', '1234');
    expect(store.visibleNotices.any((notice) => notice.title == 'Reunião'), isTrue);
  });

  test('líder adiciona salas, mas sala reservada não pode ser removida', () async {
    final store = await AppStore.load();
    await store.login(AppStore.leaderName, AppStore.leaderPassword);
    await store.addRoom('Laboratório de Robótica');
    expect(store.rooms, contains('Laboratório de Robótica'));
    await expectLater(store.addRoom('laboratório de robótica'), throwsA(isA<AppMessage>()));
    await store.addReservation(
      room: 'Laboratório de Robótica',
      date: DateTime(2026, 11, 25),
      startMinutes: 8 * 60,
      endMinutes: 9 * 60,
      note: 'Aula de sistemas',
    );
    await expectLater(store.removeRoom('Laboratório de Robótica'), throwsA(isA<AppMessage>()));
    await store.removeReservation(store.reservations.single.id);
    await store.removeRoom('Laboratório de Robótica');
    expect(store.rooms, isNot(contains('Laboratório de Robótica')));
  });

  test('carona mostra nome de quem reservou e continua após reiniciar', () async {
    var store = await AppStore.load();
    await store.register('Motorista', '1234', course: 'Direito');
    await store.addRide(
      origin: 'Complexo', destination: 'Centro',
      date: DateTime(2026, 12, 2), time: '08:00',
      seats: 2, meetingPoint: 'Portaria', vehicleDescription: 'Onix azul',
    );
    await store.logout();
    await store.register('Ana Silva', '1234', course: 'Direito');
    await store.reserveRide(store.rides.single.id);
    expect(store.passengerNames(store.rides.single), ['Ana Silva']);
    store = await AppStore.load();
    expect(store.passengerNames(store.rides.single), ['Ana Silva']);
    expect(store.rides.single.availableSeats, 1);
  });

  test('item com foto desaparece após confirmação e não volta após reiniciar', () async {
    var store = await AppStore.load();
    await store.register('Pessoa que encontrou', '1234', course: 'Direito');
    await store.addFoundItem('Chave', 'Chave prata', 'Portaria', imageBase64: 'AA==');
    final id = store.foundItems.single.id;
    expect(store.availableFoundItems.single.imageBase64, 'AA==');
    await store.logout();
    await store.register('Outro aluno', '1234', course: 'Direito');
    await expectLater(store.confirmFoundItemRetrieved(id, 'Proprietário'), throwsA(isA<AppMessage>()));
    await store.logout();
    await store.login('Pessoa que encontrou', '1234');
    await store.confirmFoundItemRetrieved(id, 'Proprietário');
    expect(store.availableFoundItems, isEmpty);
    expect(store.foundItems.single.retrievedByName, 'Proprietário');
    expect(store.foundItems.single.imageBase64, isNull);
    store = await AppStore.load();
    expect(store.availableFoundItems, isEmpty);
    expect(store.foundItems.single.retrievedAt, isNotNull);
  });

  test('nova carona exige destino, descrição do carro e origem válida', () async {
    final store = await AppStore.load();
    await store.register('Motorista', '1234', course: 'Direito');
    Future<void> oferecer(String origem, String destino, String carro) => store.addRide(
      origin: origem,
      destination: destino,
      date: DateTime(2026, 12, 12),
      time: '18:00',
      seats: 2,
      meetingPoint: 'Portaria do campus',
      vehicleDescription: carro,
    );
    await expectLater(oferecer('Bairro', 'Centro', 'Gol branco'), throwsA(isA<AppMessage>()));
    await expectLater(oferecer('Centro', ' ', 'Gol branco'), throwsA(isA<AppMessage>()));
    await expectLater(oferecer('Complexo', 'Praça', ' '), throwsA(isA<AppMessage>()));
    expect(store.rides, isEmpty);
    await oferecer('Centro', 'Rodoviária', 'Gol branco');
    expect(store.rides.single.destination, 'Rodoviária');
    expect(store.rides.single.contact, isNull);
  });

  test('destino livre, contato opcional e carro são salvos entre sessões', () async {
    var store = await AppStore.load();
    await store.register('Motorista', '1234', course: 'Direito');
    await store.addRide(
      origin: 'Complexo',
      destination: 'Praça central, Matipó',
      date: DateTime(2026, 12, 12),
      time: '19:00',
      seats: 3,
      meetingPoint: 'Entrada principal',
      vehicleDescription: 'Onix branco, quatro portas',
      contact: 'WhatsApp (00) 99999-9999',
    );
    store = await AppStore.load();
    final ride = store.rides.single;
    expect(ride.origin, 'Complexo');
    expect(ride.destination, 'Praça central, Matipó');
    expect(ride.vehicleDescription, 'Onix branco, quatro portas');
    expect(ride.contact, 'WhatsApp (00) 99999-9999');
    expect(ride.availableSeats, 3);
  });

  test('carona antiga é carregada mesmo sem campos de carro e contato', () {
    final ride = RideOffer.fromJson({
      'id': 'antiga', 'origin': 'Centro', 'destination': 'Complexo',
      'date': '2026-11-25T08:00:00.000', 'time': '08:00', 'seats': 2,
      'meetingPoint': 'Portaria', 'authorId': 'motorista',
      'authorName': 'Pessoa', 'passengerIds': <String>[],
    });
    expect(ride.vehicleDescription, isEmpty);
    expect(ride.contact, isNull);
    expect(ride.toJson()['vehicleDescription'], '');
  });

}

