import 'package:connectvertix/app_store.dart';
import 'package:connectvertix/screens/dashboard.dart';
import 'package:connectvertix/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a barra inferior fica no rodapé e não esconde o painel', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final store = await AppStore.load();
    await store.login(AppStore.leaderName, AppStore.leaderPassword);
    await tester.pumpWidget(MaterialApp(
      theme: campusTheme(),
      home: DashboardPage(store: store),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Meu Campus'), findsOneWidget);
    expect(find.text('Módulos'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Meu Campus')).dy, lessThan(150));
    expect(tester.getBottomRight(find.text('Perfil')).dy, greaterThan(650));
    expect(tester.takeException(), isNull);
  });
}
