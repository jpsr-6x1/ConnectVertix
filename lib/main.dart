import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app_store.dart';
import 'screens/auth_page.dart';
import 'screens/dashboard.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ConnectVertixApp());
}

class ConnectVertixApp extends StatefulWidget {
  const ConnectVertixApp({super.key});
  @override
  State<ConnectVertixApp> createState() => _ConnectVertixAppState();
}

class _ConnectVertixAppState extends State<ConnectVertixApp> {
  late final Future<AppStore> _loading = AppStore.load();

  @override
  Widget build(BuildContext context) => FutureBuilder<AppStore>(
        future: _loading,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return MaterialApp(
              home: Scaffold(body: Center(child: Text('Erro ao abrir os dados locais: ${snapshot.error}'))),
            );
          }
          if (!snapshot.hasData) {
            return const MaterialApp(
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
            );
          }
          final store = snapshot.data!;
          return AnimatedBuilder(
            animation: store,
            builder: (context, child) => MaterialApp(
            title: 'ConnectVertix',
            debugShowCheckedModeBanner: false,
            locale: const Locale('pt', 'BR'),
            supportedLocales: const [Locale('pt', 'BR')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: campusTheme(),
            darkTheme: campusDarkTheme(),
            themeMode: store.darkMode ? ThemeMode.dark : ThemeMode.light,
            home: AnimatedBuilder(
              animation: store,
              builder: (context, child) => store.currentUser == null
                  ? AuthPage(store: store)
                  : DashboardPage(store: store),
            ),
          ));
        },
      );
}
