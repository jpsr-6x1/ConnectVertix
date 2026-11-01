import 'package:flutter/material.dart';
import '../app_store.dart';
import '../theme.dart';
import '../ui.dart';
import 'course_selector.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.store});
  final AppStore store;
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _course;
  bool _register = false;
  bool _hidden = true;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (_register) {
        await widget.store.register(_name.text, _email.text, _password.text, course: _course ?? '');
      } else {
        await widget.store.login(_email.text, _password.text);
      }
    } on AppMessage catch (e) {
      if (mounted) showInfo(context, e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: CenterColumn(
            maxWidth: 440,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _form,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const SizedBox(height: 30),
                  Center(
                    child: Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(color: CampusColors.lavenderBlue, borderRadius: BorderRadius.circular(27)),
                      child: const Icon(Icons.school_outlined, color: CampusColors.navyDark, size: 42),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('ConnectVertix', textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 6),
                  Text('Seu campus, tudo em um só lugar.', textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 15)),
                  const SizedBox(height: 34),
                  SoftCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text(_register ? 'Crie sua conta' : 'Bem-vindo de volta!',
                        style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 7),
                    Text(_register ? 'Informe nome, e-mail, curso e senha.' : 'Entre com seu e-mail e senha.',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 24),
                    if (_register) ...[
                      TextFormField(
                        controller: _name,
                        decoration: fieldDecoration('Nome de exibição', hint: 'Ex.: Ana Silva'),
                        textInputAction: TextInputAction.next,
                        validator: requiredField,
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: fieldDecoration('E-mail', hint: 'Ex.: aluno@exemplo.com'),
                      validator: (value) => value != null && value.contains('@') && value.contains('.')
                          ? null : 'Informe um e-mail válido.',
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _hidden,
                      decoration: fieldDecoration('Senha').copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setState(() => _hidden = !_hidden),
                        ),
                      ),
                      validator: (value) => value == null || value.length < 8 ? 'Use uma senha com pelo menos 8 caracteres.' : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (_register) ...[
                      const SizedBox(height: 14),
                      CourseSelector(
                        store: widget.store,
                        key: const ValueKey('cadastro-curso'),
                        onChanged: (course) => _course = course,
                      ),
                    ],
                    const SizedBox(height: 22),
                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: _loading
                            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(_register ? 'Criar conta' : 'Entrar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        _form.currentState?.reset();
                        setState(() { _register = !_register; _course = null; });
                      },
                      child: Text(_register ? 'Já tem conta? Entrar' : 'Não tem conta? Cadastre-se'),
                    ),
                  ])),
                  const SizedBox(height: 22),
                  Text('Contas e dados sincronizados entre dispositivos · Univértix',
                    textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                ]),
              ),
            ),
          ),
        ),
      );
}
