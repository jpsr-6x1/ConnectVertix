import 'package:flutter_test/flutter_test.dart';
import 'package:connectvertix/models.dart';

void main() {
  test('perfil local apenas representa cargo vindo do banco', () {
    final student = UserAccount(id: '1', name: 'Ana', course: 'Ciência da Computação');
    final teacher = UserAccount(id: '2', name: 'Paulo', role: 'professor');
    expect(student.canManage, isFalse);
    expect(teacher.canManage, isTrue);
  });
  test('carona mostra quantidade restante pelas reservas recebidas', () {
    final ride = RideOffer(id: '1', origin: 'Centro',destination: 'Complexo',
      date: DateTime(2026,11,1),time: '18:00',seats: 2,meetingPoint: 'Portaria',
      vehicleDescription: 'Carro prata',authorId: 'motorista',authorName: 'João',
      passengerIds: ['ana']);
    expect(ride.availableSeats, 1);
  });
  test('item retirado nao fica disponivel', () {
    final item = FoundItem(id:'1', name:'Chaves',description:'',location:'Recepção',
      authorId:'1',authorName:'Ana',createdAt:DateTime(2026,11,1),
      retrievedAt:DateTime(2026,11,2));
    expect(item.isAvailable, isFalse);
  });
}
