import 'package:flutter/material.dart';
import '../app_store.dart';
import '../models.dart';
import '../theme.dart';
import '../ui.dart';
import 'forms.dart';
import 'rooms_page.dart';

void _openEditor(BuildContext context, AppStore store, EntryKind kind) {
  Navigator.push<bool>(context, MaterialPageRoute<bool>(builder: (_) => EntryEditorPage(store: store, kind: kind)));
}

Future<void> _tryDelete(BuildContext context, Future<void> Function() remove) async {
  if (!await confirmDelete(context)) return;
  try {
    await remove();
    if (context.mounted) showInfo(context, 'Excluído com sucesso.');
  } on AppMessage catch (e) {
    if (context.mounted) showInfo(context, e.message);
  }
}

class ReservationPage extends StatelessWidget {
  const ReservationPage({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, child) {
      final data = store.reservations.toList()
        ..sort((a, b) {
          final byDate = a.date.compareTo(b.date);
          return byDate != 0 ? byDate : a.startMinutes.compareTo(b.startMinutes);
        });
      return ModuleLayout(
        title: 'Reservas',
        subtitle: 'Confira laboratórios e salas. Apenas professores podem alterar reservas.',
        action: store.canManage ? PrimaryAction(
          label: 'Nova reserva', icon: Icons.add,
          onPressed: () => _openEditor(context, store, EntryKind.reservation),
        ) : const Pill('Somente professores podem reservar'),
        body: Column(children: [
          if (store.isLeader) ...[
            OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute<void>(
                builder: (_) => RoomsPage(store: store))),
              icon: const Icon(Icons.edit_outlined),
              label: Text('Gerenciar laboratórios e salas'),
            ),
            const SizedBox(height: 15),
          ],
          if (data.isEmpty) const EmptyState(
            icon: Icons.event_busy_outlined,
            title: 'Nenhuma reserva cadastrada',
            subtitle: 'As salas reservadas aparecerão aqui.',
          ),
          for (final item in data) ...[
            SoftCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.meeting_room_outlined, color: CampusColors.navy, size: 28),
                const SizedBox(width: 13),
                Expanded(child: Text(item.room, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700))),
                if (store.canManage) DeleteAction(onPressed: () => _tryDelete(context, () => store.removeReservation(item.id))),
              ]),
              DetailRow(icon: Icons.calendar_today_outlined, text: formatDate(item.date)),
              DetailRow(icon: Icons.access_time, text: '${formatMinutes(item.startMinutes)} – ${formatMinutes(item.endMinutes)}'),
              DetailRow(icon: Icons.person_outline, text: 'Reservado por ${item.authorName}'),
              if (item.note.isNotEmpty) DetailRow(icon: Icons.info_outline, text: item.note),
            ])),
            const SizedBox(height: 12),
          ],
        ]),
      );
    },
  );
}

class NoticePage extends StatelessWidget {
  const NoticePage({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, child) {
      final data = store.visibleNotices..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return ModuleLayout(
        title: 'Mural de avisos',
        subtitle: store.canManage ? 'Avisos gerais e específicos de cada curso.' :
            'Avisos gerais e recados destinados ao seu curso.',
        action: store.canManage ? PrimaryAction(
          label: 'Publicar aviso', icon: Icons.add,
          onPressed: () => _openEditor(context, store, EntryKind.notice),
        ) : const Pill('Apenas professores publicam'),
        body: Column(children: [
          if (data.isEmpty) const EmptyState(
            icon: Icons.campaign_outlined,
            title: 'Nenhum aviso publicado',
            subtitle: 'A coordenação ainda não publicou recados.',
          ),
          for (final item in data) ...[
            SoftCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CircleAvatar(backgroundColor: CampusColors.peach,
                    child: Icon(Icons.campaign_outlined, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.title, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                  Text('${item.authorName} · ${formatDate(item.createdAt)}',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                ])),
                if (store.canManage) DeleteAction(onPressed: () => _tryDelete(context, () => store.removeNotice(item.id))),
              ]),
              const SizedBox(height: 10),
              Pill(item.targetCourse ?? 'Todos os cursos'),
              const SizedBox(height: 12),
              Text(item.message, style: TextStyle(height: 1.45)),
            ])),
            const SizedBox(height: 12),
          ],
        ]),
      );
    },
  );
}

class FoundPage extends StatelessWidget {
  const FoundPage({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, child) {
      final data = store.availableFoundItems..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return ModuleLayout(
        title: 'Achados e perdidos',
        subtitle: 'Encontrou algo? Registre o item e informe onde entregou.',
        action: PrimaryAction(
          label: 'Cadastrar item encontrado', icon: Icons.add,
          onPressed: () => _openEditor(context, store, EntryKind.found),
        ),
        body: Column(children: [
          if (data.isEmpty) const EmptyState(
            icon: Icons.search_outlined,
            title: 'Nenhum item registrado',
            subtitle: 'Todos os usuários podem cadastrar itens encontrados.',
          ),
          for (final item in data) ...[
            SoftCard(color: CampusColors.mint, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.inventory_2_outlined, size: 28),
                const SizedBox(width: 12),
                Expanded(child: Text(item.name, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700))),
                if (store.isLeader || store.currentUser?.id == item.authorId)
                  DeleteAction(onPressed: () => _tryDelete(context, () => store.removeFoundItem(item.id))),
              ]),
              if (item.imageUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    item.imageUrl!, height: 200, width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Text('Imagem indisponível.'),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(item.description),
              DetailRow(icon: Icons.place_outlined, text: 'Deixado em: ${item.location}'),
              DetailRow(icon: Icons.person_outline, text: 'Publicado por ${item.authorName} · ${formatDate(item.createdAt)}'),
              ..._foundClaimActions(context,store,item),
            ])),
            const SizedBox(height: 12),
          ],
        ]),
      );
    },
  );
}

/// O dono solicita, quem achou aprova e o próprio dono confirma
/// depois da entrega. A regra também é validada pelo banco.
List<Widget> _foundClaimActions(BuildContext context, AppStore store, FoundItem item) {
  final isFinder = store.isLeader || store.currentUser?.id == item.authorId;
  final claims = store.claimsFor(item.id);
  final mine = store.myClaimFor(item.id);
  if (isFinder) {
    return [
      if (claims.isNotEmpty) const SizedBox(height: 14),
      if (claims.isNotEmpty) const Text('Solicitações de retirada:',style:TextStyle(fontWeight:FontWeight.w700)),
      for (final claim in claims) ...[
        const SizedBox(height: 8),
        Text('${claim.claimantName} — ${claim.status}'),
        if (claim.status == 'pendente') Wrap(spacing:8,children:[
          OutlinedButton(onPressed:() => _foundAction(context,
            () => store.reviewFoundClaim(item.id,claim.claimantId,true),
            'Solicitação aprovada. Entregue o item ao solicitante.'),child:const Text('Aprovar')),
          TextButton(onPressed:() => _foundAction(context,
            () => store.reviewFoundClaim(item.id,claim.claimantId,false),
            'Solicitação recusada.'),child:const Text('Recusar')),
        ]),
      ],
    ];
  }
  if (mine?.status == 'aprovada') {
    return [const SizedBox(height:14),FilledButton.icon(
      onPressed:() => _confirmMyPickup(context,store,item.id),
      icon:const Icon(Icons.check_circle_outline),
      label:const Text('Já recebi o item — confirmar retirada'),
    )];
  }
  return [const SizedBox(height:14),
    if (mine?.status == 'pendente') const Pill('Seu pedido aguarda aprovação')
    else OutlinedButton.icon(
      onPressed:() => _foundAction(context,() => store.requestFoundItem(item.id),
        'Pedido enviado para quem cadastrou o objeto.'),
      icon:const Icon(Icons.pan_tool_alt_outlined),
      label:Text(mine?.status == 'recusada' ? 'Solicitar novamente' : 'Sou o dono — solicitar retirada'),
    )];
}

Future<void> _foundAction(BuildContext context,Future<void> Function() action,String success) async {
  try { await action(); if (context.mounted) showInfo(context,success); }
  on AppMessage catch(e) { if(context.mounted) showInfo(context,e.message); }
}
Future<void> _confirmMyPickup(BuildContext context,AppStore store,String id) async {
  final confirm = await showDialog<bool>(context:context,builder:(ctx) => AlertDialog(
    title:const Text('Confirmar que recebeu o objeto?'),
    content:const Text('Confirme apenas depois da entrega. O item vai sumir da lista de achados e perdidos em todos os dispositivos.'),
    actions:[
      TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancelar')),
      FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Já recebi')),
    ],
  ));
  if (confirm == true && context.mounted) {
    await _foundAction(context,() => store.confirmMyFoundPickup(id),'Retirada confirmada!');
  }
}

class EventsPage extends StatelessWidget {
  const EventsPage({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, child) {
      final data = store.events.toList()..sort((a, b) => a.date.compareTo(b.date));
      return ModuleLayout(
        title: 'Eventos',
        subtitle: 'Acompanhe encontros, palestras e atividades do campus.',
        action: store.canManage ? PrimaryAction(
          label: 'Adicionar evento', icon: Icons.add,
          onPressed: () => _openEditor(context, store, EntryKind.event),
        ) : null,
        body: Column(children: [
          if (data.isEmpty) const EmptyState(
            icon: Icons.event_outlined,
            title: 'Nenhum evento anunciado',
            subtitle: 'As próximas atividades aparecerão aqui.',
          ),
          for (final item in data) ...[
            SoftCard(color: CampusColors.violet, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.confirmation_num_outlined, size: 30, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(child: Text(item.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
                if (store.canManage) DeleteAction(onPressed: () => _tryDelete(context, () => store.removeEvent(item.id))),
              ]),
              const SizedBox(height: 10),
              Text(item.description),
              DetailRow(icon: Icons.calendar_today_outlined, text: '${formatDate(item.date)} · ${item.time}'),
              DetailRow(icon: Icons.place_outlined, text: item.location),
            ])),
            const SizedBox(height: 12),
          ],
        ]),
      );
    },
  );
}

class RidePage extends StatelessWidget {
  const RidePage({super.key, required this.store, this.embedded = false, this.onBack});
  final AppStore store;
  final bool embedded;
  // A aba da navegação inferior não tem rota para desempilhar.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, child) {
      final data = store.rides.toList()..sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        return byDate != 0 ? byDate : a.time.compareTo(b.time);
      });
      final content = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        PrimaryAction(
          label: 'Oferecer carona', icon: Icons.add,
          onPressed: () => _openEditor(context, store, EntryKind.ride),
        ),
        const SizedBox(height: 14),
        SoftCard(
          color: CampusColors.lavenderBlue,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 10),
            Expanded(child: Text('Use somente pontos de encontro públicos e confirme a identidade de quem participa do trajeto.',
              style: TextStyle(fontSize: 13))),
          ]),
        ),
        const SizedBox(height: 20),
        if (data.isEmpty) const EmptyState(
          icon: Icons.directions_car_outlined,
          title: 'Nenhuma carona anunciada',
          subtitle: 'Ofereça uma carona saindo do Centro ou do Complexo.',
        ),
        for (final ride in data) ...[
          SoftCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const CircleAvatar(backgroundColor: CampusColors.mint,
                child: Icon(Icons.directions_car_outlined, color: CampusColors.navyDark)),
              const SizedBox(width: 11),
              Expanded(child: Text('${ride.origin} → ${ride.destination}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
              if (store.isLeader || store.currentUser?.id == ride.authorId)
                DeleteAction(onPressed: () => _tryDelete(context, () => store.removeRide(ride.id))),
            ]),
            DetailRow(icon: Icons.calendar_today_outlined, text: '${formatDate(ride.date)} às ${ride.time}'),
            DetailRow(icon: Icons.event_seat_outlined, text:
              'Vagas disponíveis: ${ride.availableSeats} de ${ride.seats}'),
            DetailRow(icon: Icons.place_outlined, text: 'Encontro: ${ride.meetingPoint}'),
            DetailRow(
              icon: Icons.directions_car_outlined,
              text: 'Carro: ${ride.vehicleDescription.isEmpty ? 'Não informado (anúncio antigo)' : ride.vehicleDescription}',
            ),
            if (ride.contact != null && ride.contact!.isNotEmpty)
              DetailRow(icon: Icons.contact_phone_outlined, text: 'Contato: ${ride.contact}'),
            DetailRow(icon: Icons.person_outline, text: 'Oferecido por ${ride.authorName}'),
            if (ride.passengerIds.isNotEmpty)
              DetailRow(
                icon: Icons.groups_outlined,
                text: 'Vagas reservadas por: ${store.passengerNames(ride).join(', ')}',
              )
            else
              const DetailRow(icon: Icons.groups_outlined, text: 'Nenhuma pessoa reservou ainda.'),
            const SizedBox(height: 12),
            if (store.currentUser?.id == ride.authorId)
              const Pill('Sua carona')
            else if (ride.passengerIds.contains(store.currentUser?.id))
              OutlinedButton.icon(
                onPressed: () => _changeRideBooking(context, () => store.cancelRideBooking(ride.id), 'Reserva cancelada.'),
                icon: const Icon(Icons.event_busy_outlined),
                label: Text('Cancelar minha reserva'),
              )
            else
              FilledButton.icon(
                onPressed: ride.availableSeats > 0
                    ? () => _changeRideBooking(context, () => store.reserveRide(ride.id), 'Vaga reservada com sucesso.')
                    : null,
                icon: const Icon(Icons.event_available_outlined),
                label: Text(ride.availableSeats > 0 ? 'Reservar uma vaga' : 'Carona lotada'),
              ),
          ])),
          const SizedBox(height: 12),
        ],
      ]);
      if (!embedded) {
        return ModuleLayout(title: 'Complexo x Centro',
          subtitle: 'Caronas saindo do Centro ou do Complexo.', body: content);
      }
      return CenterColumn(child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 30),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onBack ?? () { Navigator.of(context).maybePop(); },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Voltar ao início'),
            ),
          ),
          const SizedBox(height: 16),
          Text('Caronas', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
          const SizedBox(height: 7),
          Text('Encontre uma carona saindo do Centro ou do Complexo.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 22),
          content,
        ],
      ));
    },
  );
}

Future<void> _changeRideBooking(
  BuildContext context, Future<void> Function() action, String success,
) async {
  try {
    await action();
    if (context.mounted) showInfo(context, success);
  } on AppMessage catch (error) {
    if (context.mounted) showInfo(context, error.message);
  }
}
