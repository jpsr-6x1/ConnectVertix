import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_store.dart';
import 'screens/auth_page.dart';
import 'screens/dashboard.dart';
import 'screens/profile_page.dart';
import 'theme.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    runApp(const MaterialApp(home: Scaffold(body: Center(child: Padding(
      padding: EdgeInsets.all(28), child: SelectableText(
      'Configure SUPABASE_URL e SUPABASE_PUBLISHABLE_KEY. Consulte CONFIGURACAO_SUPABASE.md.',
      textAlign: TextAlign.center,
    ))))));
    return;
  }
  try {
    await Supabase.initialize(url:supabaseUrl,publishableKey:supabaseKey);
    runApp(const ConnectVertixApp());
  } catch (e) {
    runApp(MaterialApp(home: Scaffold(body: Center(child: Text('Erro de conexão: $e')))));
  }
}

class ConnectVertixApp extends StatefulWidget {
  const ConnectVertixApp({super.key});
  @override State<ConnectVertixApp> createState() => _ConnectVertixAppState();
}
class _ConnectVertixAppState extends State<ConnectVertixApp> {
  late final Future<AppStore> _loading = AppStore.load();
  @override Widget build(BuildContext context) => FutureBuilder<AppStore>(
    future: _loading, builder: (context,snapshot) {
      if (snapshot.hasError) return MaterialApp(home: Scaffold(
        body: Center(child: Text('Erro ao carregar dados: ${snapshot.error}'))));
      if (!snapshot.hasData) return const MaterialApp(home: Scaffold(
        body: Center(child: CircularProgressIndicator())));
      final store = snapshot.data!;
      return AnimatedBuilder(animation:store,builder:(context,child) => MaterialApp(
        title:'ConnectVertix', debugShowCheckedModeBanner:false,
        locale:const Locale('pt','BR'), supportedLocales:const [Locale('pt','BR')],
        localizationsDelegates:const [GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,GlobalCupertinoLocalizations.delegate],
        theme:campusTheme(),darkTheme:campusDarkTheme(),
        themeMode:store.darkMode ? ThemeMode.dark : ThemeMode.light,
        builder:(context,child) => MediaQuery(
          data:MediaQuery.of(context).copyWith(textScaler:TextScaler.linear(store.textScale)),
          child:child ?? const SizedBox.shrink(),
        ),
        home:store.passwordRecoveryPending
          ? PasswordRecoveryPage(store:store)
          : (store.currentUser == null ? AuthPage(store:store) : DashboardPage(store:store)),
      ));
    });
}
