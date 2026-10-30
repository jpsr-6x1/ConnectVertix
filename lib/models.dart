// Entidades do protótipo. Dados são serializados em JSON no navegador.
class UserAccount {
  UserAccount({
    required this.id,
    required this.name,
    required this.password,
    this.role = 'aluno',
    this.requestStatus = 'nenhuma',
    this.course,
  });

  final String id;
  final String name;
  final String password;
  String role; // aluno, professor ou lider
  String requestStatus; // nenhuma, pendente, recusada, aprovada
  String? course; // curso escolhido no cadastro; líder não possui curso

  bool get isLeader => role == 'lider';
  bool get canManage => role == 'professor' || role == 'lider';

  factory UserAccount.fromJson(Map<String, dynamic> map) => UserAccount(
        id: map['id'] as String,
        name: map['name'] as String,
        password: map['password'] as String,
        role: map['role'] as String? ?? 'aluno',
        requestStatus: map['requestStatus'] as String? ?? 'nenhuma',
        course: map['course'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'password': password,
        'role': role,
        'requestStatus': requestStatus,
        'course': course,
      };
}

class Reservation {
  Reservation({
    required this.id,
    required this.room,
    required this.date,
    required this.startMinutes,
    required this.endMinutes,
    required this.note,
    required this.authorId,
    required this.authorName,
  });

  final String id;
  String room; // permite que renomear espaço atualize reservas anteriores
  final DateTime date;
  final int startMinutes;
  final int endMinutes;
  final String note;
  final String authorId;
  final String authorName;

  factory Reservation.fromJson(Map<String, dynamic> m) => Reservation(
        id: m['id'] as String,
        room: m['room'] as String,
        date: DateTime.parse(m['date'] as String),
        startMinutes: m['startMinutes'] as int,
        endMinutes: m['endMinutes'] as int,
        note: m['note'] as String? ?? '',
        authorId: m['authorId'] as String,
        authorName: m['authorName'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'room': room,
        'date': date.toIso8601String(),
        'startMinutes': startMinutes,
        'endMinutes': endMinutes,
        'note': note,
        'authorId': authorId,
        'authorName': authorName,
      };
}

class Notice {
  Notice({
    required this.id,
    required this.title,
    required this.message,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.targetCourse,
  });

  final String id;
  final String title;
  final String message;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  String? targetCourse; // null: comunicado para todos; pode ser renomeado pelo líder

  factory Notice.fromJson(Map<String, dynamic> m) => Notice(
        id: m['id'] as String,
        title: m['title'] as String,
        message: m['message'] as String,
        authorId: m['authorId'] as String,
        authorName: m['authorName'] as String,
        createdAt: DateTime.parse(m['createdAt'] as String),
        targetCourse: m['targetCourse'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'authorId': authorId,
        'authorName': authorName,
        'createdAt': createdAt.toIso8601String(),
        'targetCourse': targetCourse,
      };
}

class FoundItem {
  FoundItem({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.imageBase64,
    this.retrievedAt,
    this.retrievedByName,
  });

  final String id;
  final String name;
  final String description;
  final String location;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  String? imageBase64; // imagem JPEG compactada, salva localmente
  DateTime? retrievedAt;
  String? retrievedByName;
  bool get isAvailable => retrievedAt == null;

  factory FoundItem.fromJson(Map<String, dynamic> m) => FoundItem(
        id: m['id'] as String,
        name: m['name'] as String,
        description: m['description'] as String,
        location: m['location'] as String,
        authorId: m['authorId'] as String,
        authorName: m['authorName'] as String,
        createdAt: DateTime.parse(m['createdAt'] as String),
        imageBase64: m['imageBase64'] as String?,
        retrievedAt: m['retrievedAt'] == null ? null : DateTime.parse(m['retrievedAt'] as String),
        retrievedByName: m['retrievedByName'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'location': location,
        'authorId': authorId,
        'authorName': authorName,
        'createdAt': createdAt.toIso8601String(),
        'imageBase64': imageBase64,
        'retrievedAt': retrievedAt?.toIso8601String(),
        'retrievedByName': retrievedByName,
      };
}

class RideOffer {
  RideOffer({
    required this.id,
    required this.origin,
    required this.destination,
    required this.date,
    required this.time,
    required this.seats,
    required this.meetingPoint,
    required this.vehicleDescription,
    this.contact,
    required this.authorId,
    required this.authorName,
    List<String>? passengerIds,
  }) : passengerIds = passengerIds ?? [];

  final String id;
  final String origin;
  final String destination;
  final DateTime date;
  final String time;
  final int seats; // total de vagas oferecidas
  final List<String> passengerIds; // quem reservou (uma vaga por pessoa)
  int get availableSeats => seats - passengerIds.length;
  final String meetingPoint;
  final String vehicleDescription;
  final String? contact; // Compartilhado voluntariamente pelo motorista.
  final String authorId;
  final String authorName;

  factory RideOffer.fromJson(Map<String, dynamic> m) => RideOffer(
        id: m['id'] as String,
        origin: m['origin'] as String,
        destination: m['destination'] as String,
        date: DateTime.parse(m['date'] as String),
        time: m['time'] as String,
        seats: m['seats'] as int,
        meetingPoint: m['meetingPoint'] as String? ?? '',
        // Anúncios criados antes da v4 não tinham estes campos.
        vehicleDescription: m['vehicleDescription'] as String? ?? '',
        contact: m['contact'] as String?,
        authorId: m['authorId'] as String,
        authorName: m['authorName'] as String,
        passengerIds: (m['passengerIds'] as List<dynamic>? ?? [])
            .map((id) => id as String).toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'origin': origin,
        'destination': destination,
        'date': date.toIso8601String(),
        'time': time,
        'seats': seats,
        'passengerIds': passengerIds,
        'meetingPoint': meetingPoint,
        'vehicleDescription': vehicleDescription,
        'contact': contact,
        'authorId': authorId,
        'authorName': authorName,
      };
}

class CampusEvent {
  CampusEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.location,
    required this.authorId,
  });

  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String time;
  final String location;
  final String authorId;

  factory CampusEvent.fromJson(Map<String, dynamic> m) => CampusEvent(
        id: m['id'] as String,
        title: m['title'] as String,
        description: m['description'] as String,
        date: DateTime.parse(m['date'] as String),
        time: m['time'] as String,
        location: m['location'] as String,
        authorId: m['authorId'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
        'time': time,
        'location': location,
        'authorId': authorId,
      };
}
