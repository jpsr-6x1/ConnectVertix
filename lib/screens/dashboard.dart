import 'package:flutter/material.dart';
import '../app_store.dart';
import '../models.dart';
import '../theme.dart';
import '../ui.dart';
import 'module_pages.dart';
import 'permissions_page.dart';
import 'rooms_page.dart';
import 'course_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.store});
  final AppStore store;
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _tab = 0;

  void _open(Widget page) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => page),
      );

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _tab, children: [
          _home(store),
          _agenda(store),
          RidePage(
            store: store,
            embedded: true,
            onBack: () => setState(() => _tab = 0),
          ),
          _profile(store),
        ]),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF121212) : CampusColors.neutral,
            border: Border(top: BorderSide(
              color: dark ? const Color(0xFF303030) : CampusColors.line,
            )),
          ),
          padding: const EdgeInsets.fromLTRB(8, 11, 8, 8),
          // Importante: na bottomNavigationBar, CenterColumn usava Center,
          // que se expandia na altura e empurrava o corpo da tela para fora.
          // Align(heightFactor: 1) ocupa só a altura do menu.
          child: Align(
            alignment: Alignment.center,
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: Row(children: [
                _navItem(0, Icons.home_outlined, 'Início'),
                _navItem(1, Icons.calendar_month_outlined, 'Agenda'),
                _navItem(2, Icons.directions_car_outlined, 'Caronas'),
                _navItem(3, Icons.person_outline, 'Perfil'),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final active = _tab == index;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => setState(() => _tab = index),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
              decoration: BoxDecoration(
                color: active ? (dark ? const Color(0xFF242424) : CampusColors.lavenderBlue) : Colors.transparent,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(icon, size: 25, color: active ? (dark ? const Color(0xFFB9CBFF) : CampusColors.navyDark) : Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(
              fontSize: 12,
              color: active ? (dark ? const Color(0xFFB9CBFF) : CampusColors.navyDark) : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            )),
          ]),
        ),
      ),
    );
  }

  Widget _home(AppStore store) {
    final upcoming = store.events.where((e) =>
        !DateTime(e.date.year, e.date.month, e.date.day).isBefore(
          DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
        )).toList()..sort((a, b) => a.date.compareTo(b.date));
    final CampusEvent? next = upcoming.isEmpty ? null : upcoming.first;
    final latest = store.visibleNotices..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final user = store.currentUser!;
    final trimmedName = user.name.trim();
    final initials = trimmedName.isNotEmpty
        ? trimmedName.substring(0, trimmedName.length >= 2 ? 2 : 1).toUpperCase()
        : 'CV';
    return CenterColumn(child: ListView(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
      children: [
        Row(children: [
          CircleAvatar(radius: 25, backgroundColor: CampusColors.lavenderBlue,
              child: Text(initials, style: TextStyle(color: CampusColors.navyDark, fontWeight: FontWeight.w700, fontSize: 16))),
          const SizedBox(width: 15),
          Expanded(child: Text('Meu Campus', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700))),
          Stack(clipBehavior: Clip.none, children: [
            IconButton(
              tooltip: store.isLeader ? 'Aprovar professores' : 'Solicitar permissão de professor',
              onPressed: () => _open(PermissionsPage(store: store)),
              icon: const Icon(Icons.verified_user_outlined, size: 27),
            ),
            if (store.isLeader && store.pendingRequests.isNotEmpty)
              Positioned(right: 8, top: 5, child: Container(width: 9, height: 9,
                decoration: const BoxDecoration(color: Color(0xFFCC3838), shape: BoxShape.circle))),
          ]),
          Stack(clipBehavior: Clip.none, children: [
            IconButton(
              tooltip: 'Avisos',
              onPressed: () => _open(NoticePage(store: store)),
              icon: const Icon(Icons.notifications_none_rounded, size: 29),
            ),
            if (store.visibleNotices.isNotEmpty)
              Positioned(right: 8, top: 6, child: Container(width: 9, height: 9,
                decoration: const BoxDecoration(color: Color(0xFFCC3838), shape: BoxShape.circle))),
          ]),
        ]),
        const SizedBox(height: 28),
        Text(getGreeting(), style: TextStyle(fontSize: 29, fontWeight: FontWeight.w500)),
        const SizedBox(height: 3),
        Text('Univértix · Matipó', style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 30),
        Container(
          decoration: BoxDecoration(color: CampusColors.navy, borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.all(29),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('PRÓXIMO EVENTO', style: TextStyle(color: Color(0xFFE1E8F9), letterSpacing: 1.2, fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            Text(next?.title ?? 'Nenhum evento programado',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 9),
            Text(next == null ? 'Confira os eventos do campus.' : '${formatDate(next.date)} · ${next.time}',
              style: TextStyle(color: Color(0xFFE2E9F6), fontSize: 15)),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: () => _open(EventsPage(store: store)),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: CampusColors.navyDark,
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 17),
                shape: const StadiumBorder(),
              ),
              child: Text('Ver programação', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
        const SizedBox(height: 30),
        const SectionHeading('Módulos'),
        LayoutBuilder(builder: (context, bounds) {
          final count = bounds.maxWidth >= 760 ? 4 : 2;
          return GridView.count(
            crossAxisCount: count,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            mainAxisSpacing: 13,
            crossAxisSpacing: 13,
            childAspectRatio: count == 4 ? 1.03 : bounds.maxWidth < 540 ? 0.88 : 1.58,
            children: [
              _feature('Reservas', 'Laboratórios e salas', Icons.calendar_today_outlined,
                  CampusColors.lavenderBlue, () => _open(ReservationPage(store: store))),
              _feature('Mural de avisos', 'Recados da coordenação', Icons.campaign_outlined,
                  CampusColors.peach, () => _open(NoticePage(store: store))),
              _feature('Achados e perdidos', 'Itens encontrados', Icons.search_outlined,
                  CampusColors.mint, () => _open(FoundPage(store: store))),
              _feature('Eventos', 'Programação do campus', Icons.confirmation_num_outlined,
                  CampusColors.violet, () => _open(EventsPage(store: store))),
            ],
          );
        }),
        const SizedBox(height: 29),
        SectionHeading('Avisos recentes', trailing: TextButton(
          onPressed: () => _open(NoticePage(store: store)),
          child: Text('Ver todos'),
        )),
        if (latest.isEmpty)
          const EmptyState(icon: Icons.notifications_none, title: 'Nenhum aviso por enquanto', subtitle: 'As notícias aparecerão aqui.'),
        if (latest.isNotEmpty)
          SoftCard(
            color: CampusColors.neutral,
            child: Column(children: [
              for (var i = 0; i < (latest.length > 2 ? 2 : latest.length); i++) ...[
                InkWell(
                  onTap: () => _open(NoticePage(store: store)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: i.isEven ? CampusColors.peach : CampusColors.lavenderBlue,
                        child: Icon(i.isEven ? Icons.schedule_outlined : Icons.emoji_events_outlined, color: Theme.of(context).colorScheme.onSurface),
                      ),
                      const SizedBox(width: 15),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(latest[i].title, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        Text(latest[i].message, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ])),
                      const Icon(Icons.chevron_right, size: 25),
                    ]),
                  ),
                ),
                if (i == 0 && latest.length > 1) const Divider(height: 20),
              ],
            ]),
          ),
      ],
    ));
  }

  Widget _feature(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) =>
      Material(
        color: Theme.of(context).brightness == Brightness.dark
            ? Color.lerp(color, const Color(0xFF151515), .78)! : color,
        borderRadius: BorderRadius.circular(25),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(25),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, size: 29, color: Theme.of(context).colorScheme.onSurface),
              const Spacer(),
              Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 17, fontWeight: FontWeight.w700)),
              Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12)),
            ]),
          ),
        ),
      );

  Widget _agenda(AppStore store) => CenterColumn(child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 30),
        children: [
          Text('Minha agenda', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
          const SizedBox(height: 7),
          Text('Organize os espaços e acompanhe os eventos do campus.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 26),
          _agendaButton('Reservas de salas', 'Consulte os horários disponíveis e as reservas existentes.',
              Icons.meeting_room_outlined, CampusColors.lavenderBlue,
              () => _open(ReservationPage(store: store))),
          const SizedBox(height: 14),
          _agendaButton('Eventos', 'Veja a programação acadêmica divulgada pela coordenação.',
              Icons.event_available_outlined, CampusColors.violet,
              () => _open(EventsPage(store: store))),
          const SizedBox(height: 27),
          const SectionHeading('Resumo'),
          SoftCard(
            color: CampusColors.neutral,
            child: Row(children: [
              Expanded(child: _summaryNumber('${store.reservations.length}', 'reservas')),
              const SizedBox(height: 55, child: VerticalDivider()),
              Expanded(child: _summaryNumber('${store.events.length}', 'eventos')),
            ]),
          ),
        ],
      ));

  Widget _summaryNumber(String number, String title) => Column(children: [
    Text(number, style: TextStyle(fontSize: 29, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),
    Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
  ]);

  Widget _agendaButton(String title, String subtitle, IconData icon, Color color, VoidCallback action) =>
      Material(color: Theme.of(context).brightness == Brightness.dark
          ? Color.lerp(color, const Color(0xFF151515), .78)! : color,
          borderRadius: BorderRadius.circular(22), child: InkWell(
        onTap: action,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Row(children: [
            Icon(icon, size: 36),
            const SizedBox(width: 19),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(subtitle),
            ])),
            const Icon(Icons.chevron_right),
          ]),
        ),
      ));

  Widget _profile(AppStore store) {
    final user = store.currentUser!;
    final role = user.isLeader ? 'Líder' : user.canManage ? 'Professor' : 'Aluno';
    return CenterColumn(child: ListView(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
      children: [
        Text('Meu perfil', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
        const SizedBox(height: 26),
        SoftCard(child: Row(children: [
          CircleAvatar(radius: 34, backgroundColor: CampusColors.lavenderBlue,
              child: const Icon(Icons.person_outline, size: 33, color: CampusColors.navy)),
          const SizedBox(width: 17),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user.name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            Pill(role),
            if (!user.isLeader) ...[
              const SizedBox(height: 6),
              Text('Curso: ${user.course ?? 'Não informado'}',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ])),
        ])),
        const SizedBox(height: 17),
        SoftCard(color: CampusColors.neutral, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Permissões da conta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 7),
          Text(user.isLeader ? 'Você pode analisar solicitações e gerenciar os módulos.' :
            user.canManage ? 'Você pode publicar avisos, eventos e criar reservas.' :
            'Você pode ver os módulos e publicar itens e caronas.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 15),
          PrimaryAction(
            icon: Icons.verified_user_outlined,
            label: store.isLeader ? 'Analisar solicitações' : 'Permissão de professor',
            onPressed: () => _open(PermissionsPage(store: store)),
          ),
        ])),
        const SizedBox(height: 17),
        SoftCard(child: SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text('Tema escuro', style: TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('Alterar entre aparência clara e escura'),
          secondary: Icon(store.darkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
          value: store.darkMode,
          onChanged: (value) => store.setDarkMode(value),
        )),
        if (!user.isLeader) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _open(CoursePage(store: store)),
            icon: const Icon(Icons.school_outlined),
            label: Text('Alterar meu curso'),
          ),
        ],
        if (user.isLeader) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _open(CoursesPage(store: store)),
            icon: const Icon(Icons.school_outlined),
            label: Text('Gerenciar cursos'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _open(RoomsPage(store: store)),
            icon: const Icon(Icons.edit_outlined),
            label: Text('Gerenciar laboratórios e salas'),
          ),
        ],
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => store.logout(),
          icon: const Icon(Icons.logout),
          label: Text('Sair da conta'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
        ),
        const SizedBox(height: 18),
        Text('ConnectVertix · versão demonstrativa (dados locais neste dispositivo)',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    ));
  }
}
