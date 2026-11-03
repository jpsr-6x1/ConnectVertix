import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';

class AppMessage implements Exception {
  const AppMessage(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Fachada para a interface v4. O banco de dados e a autorizacao ficam
/// no Supabase, nao nas listas abaixo. As listas sao apenas cache de leitura.
class AppStore extends ChangeNotifier {
  AppStore._(this._prefs);
  final SharedPreferences _prefs;
  final SupabaseClient _db = Supabase.instance.client;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  StreamSubscription<AuthState>? _authSubscription;
  Timer? _refreshTimer;
  bool _refreshing = false;
  bool _again = false;
  bool _darkMode = false;
  double _textScale = 1.0;
  double get textScale => _textScale;
  bool _passwordRecoveryPending = false;
  bool get passwordRecoveryPending => _passwordRecoveryPending;
  bool get darkMode => _darkMode;

  final List<UserAccount> users = [];
  final List<Reservation> reservations = [];
  final List<Notice> notices = [];
  final List<FoundItem> foundItems = [];
  final List<FoundClaim> foundClaims = [];
  final List<RideOffer> rides = [];
  final List<CampusEvent> events = [];
  final List<AgendaItem> agendaItems = [];
  final List<String> rooms = [];
  final List<String> courses = [];
  String? get _uid => _db.auth.currentUser?.id;
  String? get currentEmail => _db.auth.currentUser?.email;
  UserAccount? get currentUser {
    for (final user in users) { if (user.id == _uid) return user; }
    return null;
  }
  bool get canManage => currentUser?.canManage ?? false;
  bool get isLeader => currentUser?.isLeader ?? false;
  List<UserAccount> get pendingRequests => users.where((u) => u.requestStatus == 'pendente').toList();
  List<UserAccount> get professors => users.where((u) => u.role == 'professor').toList();
  List<String> get allCourses => List<String>.from(courses)..sort();
  List<String> passengerNames(RideOffer ride) => [for (final id in ride.passengerIds)
    users.where((u) => u.id == id).map((u) => u.name).firstOrNull ?? 'Usuário'];
  List<FoundItem> get availableFoundItems => foundItems.where((f) => f.isAvailable).toList();
  List<Notice> get visibleNotices => notices.where((n) => canManage || n.targetCourse == null || n.targetCourse == currentUser?.course).toList();

  List<FoundClaim> claimsFor(String itemId) => foundClaims.where((c) => c.itemId == itemId).toList();
  FoundClaim? myClaimFor(String itemId) => foundClaims.where((c) => c.itemId == itemId && c.claimantId == _uid).firstOrNull;

  static Future<AppStore> load() async {
    final store = AppStore._(await SharedPreferences.getInstance());
    store._darkMode = store._prefs.getBool('connectvertix_dark_theme') ?? false;
    store._textScale = (store._prefs.getDouble('connectvertix_text_scale') ?? 1).clamp(.85, 1.35).toDouble();
    store._authSubscription = store._db.auth.onAuthStateChange.listen((authState) async {
      if (authState.event == AuthChangeEvent.passwordRecovery) {
        store._passwordRecoveryPending = true;
        store.notifyListeners();
      }
      store._attachRealtime();
      await store.refresh();
    }, onError: (Object error, StackTrace stack) {
      debugPrint('Auth: $error');
    });
    await store.refresh();
    store._attachRealtime();
    return store;
  }

  void _attachRealtime() {
    for (final sub in _subscriptions) { sub.cancel(); }
    _subscriptions.clear();
    final tables = _uid == null ? <String, List<String>>{
      'courses': ['name']
    } : <String,List<String>>{
      'profiles':['id'], 'courses':['name'], 'rooms':['name'],
      'reservations':['id'], 'notices':['id'], 'found_items':['id'],
      'found_item_claims':['item_id','claimant_id'], 'rides':['id'],
      'ride_bookings':['ride_id','user_id'], 'events':['id'],
      'agenda_items':['id']
    };
    for (final entry in tables.entries) {
      final subscription = _db.from(entry.key).stream(primaryKey: entry.value).listen(
        (_) => _scheduleRefresh(), onError: (Object e, StackTrace s) => debugPrint('Realtime ${entry.key}: $e'));
      _subscriptions.add(subscription);
    }
  }

  void _scheduleRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(milliseconds: 350), () => refresh());
  }
  Future<List<Map<String,dynamic>>> _all(String table) async {
    final rows = await _db.from(table).select();
    return (rows as List).map((e) => Map<String,dynamic>.from(e as Map)).toList();
  }
  static String _date(DateTime date) => '${date.year.toString().padLeft(4,'0')}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';
  String _name(String? id) => users.where((u) => u.id == id).map((u) => u.name).firstOrNull ?? 'Usuário';

  Future<void> refresh() async {
    if (_refreshing) { _again = true; return; }
    _refreshing = true;
    try {
      final courseRows = await _all('courses');
      courses..clear()..addAll(courseRows.map((e) => e['name'] as String));
      if (_uid == null) {
        users.clear(); reservations.clear(); notices.clear(); rooms.clear();
        foundItems.clear(); foundClaims.clear(); rides.clear(); events.clear(); agendaItems.clear();
        notifyListeners(); return;
      }
      final rows = await Future.wait([
        _all('profiles'), _all('rooms'), _all('reservations'), _all('notices'),
        _all('found_items'), _all('found_item_claims'), _all('rides'),
        _all('ride_bookings'), _all('events'), _all('agenda_items')
      ]);
      users..clear()..addAll(rows[0].map((m) => UserAccount(
        id:m['id'] as String, name:m['display_name'] as String,
        course:m['course'] as String?, role:m['role'] as String? ?? 'aluno',
        requestStatus:m['request_status'] as String? ?? 'nenhuma')));
      rooms..clear()..addAll(rows[1].map((m) => m['name'] as String));
      reservations..clear()..addAll(rows[2].map((m) => Reservation.fromJson({
        'id':m['id'], 'room':m['room'], 'date':m['on_date'],
        'startMinutes':m['start_minutes'], 'endMinutes':m['end_minutes'],
        'note':m['note'], 'authorId':m['author_id'], 'authorName':_name(m['author_id'] as String?)
      })));
      notices..clear()..addAll(rows[3].map((m) => Notice.fromJson({
        'id':m['id'], 'title':m['title'], 'message':m['message'],
        'authorId':m['author_id'], 'authorName':_name(m['author_id'] as String?),
        'createdAt':m['created_at'], 'targetCourse':m['target_course']
      })));
      final found = <FoundItem>[];
      for (final m in rows[4]) {
        String? url;
        if (m['image_path'] != null) {
          try { url = await _db.storage.from('found-items').createSignedUrl(m['image_path'] as String, 3600); }
          catch (e) { debugPrint('Foto indisponível: $e'); }
        }
        found.add(FoundItem.fromJson({
          'id':m['id'],'name':m['name'],'description':m['description'],
          'location':m['location'],'authorId':m['author_id'],
          'authorName':_name(m['author_id'] as String?), 'createdAt':m['created_at'],
          'imageUrl':url, 'retrievedAt':m['retrieved_at'],
          'retrievedByName':_name(m['retrieved_by_id'] as String?)
        }));
      }
      foundItems..clear()..addAll(found);
      foundClaims..clear()..addAll(rows[5].map((m) => FoundClaim(
        itemId:m['item_id'] as String, claimantId:m['claimant_id'] as String,
        status:m['status'] as String, claimantName:_name(m['claimant_id'] as String?))));
      rides..clear()..addAll(rows[6].map((m) => RideOffer.fromJson({
        'id':m['id'],'origin':m['origin'],'destination':m['destination'],
        'date':m['ride_date'],'time':m['ride_time'],'seats':m['seats'],
        'meetingPoint':m['meeting_point'],'vehicleDescription':m['vehicle_description'],
        'contact':m['contact'],'authorId':m['author_id'],
        'authorName':_name(m['author_id'] as String?),
        'passengerIds':[for (final b in rows[7]) if (b['ride_id'] == m['id']) b['user_id']]
      })));
      events..clear()..addAll(rows[8].map((m) => CampusEvent.fromJson({
        'id':m['id'],'title':m['title'],'description':m['description'],
        'date':m['event_date'],'time':m['event_time'],'location':m['location'],
        'authorId':m['author_id']
      })));
      agendaItems..clear()..addAll(rows[9].map((m) => AgendaItem(
        id:m['id'] as String, title:m['title'] as String,
        kind:m['kind'] as String, date:DateTime.parse(m['on_date'] as String),
        description:m['description'] as String? ?? '',
        time:m['at_time'] as String?, targetCourse:m['target_course'] as String?,
        authorId:m['author_id'] as String,
      )));
      notifyListeners();
    } catch (e) {
      debugPrint('Erro de sincronização: $e');
      rethrow;
    } finally {
      _refreshing = false;
      if (_again) { _again = false; _scheduleRefresh(); }
    }
  }

  Future<void> _run(Future<dynamic> Function() fn) async {
    try { await fn(); await refresh(); }
    on PostgrestException catch (e) { throw AppMessage(e.message); }
    on AuthException catch (e) { throw AppMessage(e.message); }
    on StorageException catch (e) { throw AppMessage(e.message); }
    on AppMessage { rethrow; }
    catch (e) { debugPrint('Operação falhou: $e'); throw const AppMessage('Falha de conexão. Confira sua internet e tente novamente.'); }
  }
  String _requireUser() => _uid ?? (throw const AppMessage('Entre na sua conta.'));
  void _requireProfessor() { if (!canManage) throw const AppMessage('Apenas professores podem alterar este módulo.'); }
  void _requireLeader() { if (!isLeader) throw const AppMessage('Apenas o líder pode fazer essa alteração.'); }

  Future<void> register(String name,String email,String password,{required String course}) async {
    if (name.trim().length < 3) throw const AppMessage('Informe um nome com pelo menos 3 letras.');
    if (!courses.contains(course)) throw const AppMessage('Selecione um curso.');
    if (password.length < 8) throw const AppMessage('Use uma senha com pelo menos 8 caracteres.');
    try {
      final response = await _db.auth.signUp(email:email.trim(),password:password,
        data:{'display_name':name.trim(),'course':course});
      if (response.session == null) {
        throw const AppMessage('Cadastro enviado. Confirme o e-mail para ativar a conta e depois faça login.');
      }
      await refresh();
    } on AuthException catch (e) { throw AppMessage(e.message); }
  }
  Future<void> login(String email,String password) async {
    try { await _db.auth.signInWithPassword(email:email.trim(),password:password); await refresh(); }
    on AuthException catch (e) { throw AppMessage(e.message); }
  }
  Future<void> logout() async { await _db.auth.signOut(); await refresh(); }
  Future<void> setDarkMode(bool value) async {
    _darkMode=value; await _prefs.setBool('connectvertix_dark_theme',value); notifyListeners();
  }
  Future<void> setTextScale(double scale) async {
    _textScale = scale.clamp(.85, 1.35).toDouble();
    await _prefs.setDouble('connectvertix_text_scale', _textScale);
    notifyListeners();
  }

  /// Envia o link pelo Supabase Auth; o dominio precisa constar nas URLs permitidas.
  Future<void> sendPasswordReset(String email) async {
    final normalized = email.trim();
    if (!normalized.contains('@')) throw const AppMessage('Informe seu e-mail.');
    try {
      await _db.auth.resetPasswordForEmail(normalized,
        redirectTo: kIsWeb ? Uri.base.origin : null);
    } on AuthException catch (e) { throw AppMessage(e.message); }
  }

  Future<void> changePassword(String password) async {
    if (password.length < 8) throw const AppMessage('A senha deve ter pelo menos 8 caracteres.');
    try {
      await _db.auth.updateUser(UserAttributes(password:password));
      _passwordRecoveryPending = false;
      notifyListeners();
    } on AuthException catch (e) { throw AppMessage(e.message); }
  }

  Future<void> updateMyProfile({required String name, String? course, String? email}) async {
    final cleanName = name.trim();
    if (cleanName.length < 3) throw const AppMessage('Informe um nome com pelo menos 3 letras.');
    final me = currentUser;
    if (me == null) throw const AppMessage('Faça login novamente.');
    if (!me.isLeader && (course == null || !courses.contains(course))) {
      throw const AppMessage('Selecione um curso válido.');
    }
    await _run(() => _db.from('profiles').update({
      'display_name': cleanName,
      if (!me.isLeader) 'course': course,
    }).eq('id', _requireUser()));
    final newEmail = email?.trim();
    if (newEmail != null && newEmail.isNotEmpty && newEmail != _db.auth.currentUser?.email) {
      try { await _db.auth.updateUser(UserAttributes(email:newEmail)); }
      on AuthException catch(e) { throw AppMessage('Nome salvo; não foi possível alterar e-mail: ${e.message}'); }
    }
  }

  Future<void> addAgendaItem({required String title, required String kind,
    required DateTime date, required String description, String? time, String? targetCourse}) async {
    _requireProfessor();
    if (title.trim().isEmpty) throw const AppMessage('Informe o título da atividade.');
    if (targetCourse != null && !courses.contains(targetCourse)) throw const AppMessage('Curso inválido.');
    await _run(() => _db.from('agenda_items').insert({
      'title': title.trim(), 'kind':kind, 'on_date':_date(date),
      'description':description.trim(), 'at_time':time,
      'target_course':targetCourse,'author_id':_requireUser()
    }));
  }
  Future<void> removeAgendaItem(String id) async {
    _requireProfessor();
    await _run(() => _db.from('agenda_items').delete().eq('id',id));
  }

  Future<void> updateCourse(String course) async {
    if (!courses.contains(course)) throw const AppMessage('Curso inválido.');
    await _run(() => _db.from('profiles').update({'course':course}).eq('id',_requireUser()));
  }
  Future<void> addRoom(String name) async { _requireLeader(); await _run(() => _db.from('rooms').insert({'name':name.trim()})); }
  Future<void> renameRoom(String oldName,String newName) async { _requireLeader(); await _run(() => _db.from('rooms').update({'name':newName.trim()}).eq('name',oldName)); }
  Future<void> removeRoom(String name) async { _requireLeader(); await _run(() => _db.from('rooms').delete().eq('name',name)); }
  Future<void> addCourse(String name) async { _requireLeader(); await _run(() => _db.from('courses').insert({'name':name.trim()})); }
  Future<void> renameCourse(String oldName,String newName) async { _requireLeader(); await _run(() => _db.from('courses').update({'name':newName.trim()}).eq('name',oldName)); }
  Future<void> removeCourse(String name) async { _requireLeader(); await _run(() => _db.from('courses').delete().eq('name',name)); }
  Future<void> requestProfessor() async { await _run(() => _db.rpc('request_professor')); }
  Future<void> decideRequest(String userId,bool approve) async { _requireLeader(); await _run(() => _db.rpc('decide_professor',params:{'p_user':userId,'p_approve':approve})); }
  Future<void> revokeProfessor(String userId) async { _requireLeader(); await _run(() => _db.rpc('revoke_professor',params:{'p_user':userId})); }

  Future<void> addReservation({required String room,required DateTime date,
    required int startMinutes,required int endMinutes,required String note}) async {
    _requireProfessor();
    await _run(() => _db.from('reservations').insert({
      'room':room,'on_date':_date(date),'start_minutes':startMinutes,
      'end_minutes':endMinutes,'note':note,'author_id':_requireUser()
    }));
  }
  Future<void> removeReservation(String id) async { _requireProfessor(); await _run(() => _db.from('reservations').delete().eq('id',id)); }
  Future<void> addNotice(String title,String message,{String? targetCourse}) async {
    _requireProfessor(); await _run(() => _db.from('notices').insert({
      'title':title.trim(),'message':message.trim(),
      'target_course':targetCourse,'author_id':_requireUser()
    }));
  }
  Future<void> removeNotice(String id) async { _requireProfessor(); await _run(() => _db.from('notices').delete().eq('id',id)); }
  Future<void> addFoundItem(String name,String description,String location,{String? imageBase64}) async {
    final uid = _requireUser();
    String? path;
    try {
      if (imageBase64 != null) {
        final bytes = Uint8List.fromList(base64Decode(imageBase64));
        if (bytes.length > 1024 * 1024) throw const AppMessage('Imagem muito grande.');
        path = '$uid/${DateTime.now().microsecondsSinceEpoch}.jpg';
        await _db.storage.from('found-items').uploadBinary(path,bytes,
          fileOptions:const FileOptions(contentType:'image/jpeg'));
      }
      await _run(() => _db.from('found_items').insert({
        'name':name.trim(),'description':description.trim(),
        'location':location.trim(),'author_id':uid,'image_path':path
      }));
    } catch (e) {
      if (path != null) { try { await _db.storage.from('found-items').remove([path]); } catch (_) {} }
      if (e is AppMessage) rethrow;
      if (e is StorageException) throw AppMessage(e.message);
      rethrow;
    }
  }
  Future<void> requestFoundItem(String id) async { await _run(() => _db.rpc('claim_found_item',params:{'p_item':id})); }
  Future<void> reviewFoundClaim(String id,String claimantId,bool approve) async {
    await _run(() => _db.rpc('review_found_claim',params:{'p_item':id,'p_claimant':claimantId,'p_approve':approve}));
  }
  Future<void> confirmMyFoundPickup(String id) async { await _run(() => _db.rpc('confirm_found_pickup',params:{'p_item':id})); }
  Future<void> removeFoundItem(String id) async { await _run(() => _db.from('found_items').delete().eq('id',id)); }

  Future<void> addRide({required String origin,required String destination,
    required DateTime date,required String time,required int seats,
    required String meetingPoint,required String vehicleDescription,String? contact}) async {
    await _run(() => _db.from('rides').insert({
      'origin':origin,'destination':destination.trim(),'ride_date':_date(date),
      'ride_time':time,'seats':seats,'meeting_point':meetingPoint.trim(),
      'vehicle_description':vehicleDescription.trim(),
      'contact':contact?.trim().isEmpty == true ? null : contact?.trim(),
      'author_id':_requireUser()
    }));
  }
  Future<void> reserveRide(String id) async { await _run(() => _db.rpc('book_ride',params:{'p_ride':id})); }
  Future<void> cancelRideBooking(String id) async { await _run(() => _db.rpc('cancel_ride',params:{'p_ride':id})); }
  Future<void> removeRide(String id) async { await _run(() => _db.from('rides').delete().eq('id',id)); }
  Future<void> addEvent({required String title,required String description,
    required DateTime date,required String time,required String location}) async {
    _requireProfessor(); await _run(() => _db.from('events').insert({
      'title':title.trim(),'description':description.trim(),'event_date':_date(date),
      'event_time':time,'location':location.trim(),'author_id':_requireUser()
    }));
  }
  Future<void> removeEvent(String id) async { _requireProfessor(); await _run(() => _db.from('events').delete().eq('id',id)); }

  @override void dispose() {
    _authSubscription?.cancel(); _refreshTimer?.cancel();
    for (final sub in _subscriptions) { sub.cancel(); }
    super.dispose();
  }
}
