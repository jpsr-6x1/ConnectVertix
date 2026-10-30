import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectvertix/app_store.dart';
import 'package:connectvertix/screens/dashboard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('a aba Caronas possui botão para voltar ao início', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await AppStore.load();
    await store.register('Aluno', '1234', course: 'Direito');
    await tester.pumpWidget(MaterialApp(home: DashboardPage(store: store)));

    await tester.tap(find.text('Caronas').last);
    await tester.pumpAndSettle();
    expect(find.text('Voltar ao início'), findsOneWidget);

    await tester.tap(find.text('Voltar ao início'));
    await tester.pumpAndSettle();
    expect(find.text('Meu Campus'), findsWidgets);
    expect(find.text('Voltar ao início'), findsNothing);
  });
}
