import 'package:flutter/material.dart';
import '../app_store.dart';
import '../theme.dart';
import '../ui.dart';

class PermissionsPage extends StatelessWidget {
  const PermissionsPage({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, child) {
    final user = store.currentUser!;
    if (store.isLeader) return _leaderView(context);
    final status = user.canManage
        ? 'Sua conta já possui permissão de professor.'
        : user.requestStatus == 'pendente'
            ? 'Sua solicitação está aguardando a aprovação da conta líder.'
            : user.requestStatus == 'recusada'
                ? 'Sua solicitação anterior não foi aprovada. Você pode enviar outra.'
                : 'Peça autorização para criar reservas e publicar avisos e eventos.';
    return ModuleLayout(
      title: 'Permissão de professor',
      subtitle: 'O líder do projeto analisa os pedidos de acesso.',
      body: Column(children: [
        SoftCard(color: CampusColors.lavenderBlue, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.verified_user_outlined, size: 38, color: CampusColors.navy),
          const SizedBox(height: 17),
          Text('Seu acesso', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(status),
          if (!user.canManage && user.requestStatus != 'pendente') ...[
            const SizedBox(height: 18),
            PrimaryAction(icon: Icons.send_outlined, label: 'Solicitar permissão', onPressed: () async {
              try {
                await store.requestProfessor();
                if (context.mounted) showInfo(context, 'Pedido enviado à conta líder.');
              } on AppMessage catch (e) {
                if (context.mounted) showInfo(context, e.message);
              }
            }),
          ],
        ])),
      ]),
    );
    },
  );

  Widget _leaderView(BuildContext context) {
    final pending = store.pendingRequests;
    final professors = store.professors;
    return ModuleLayout(
      title: 'Gerenciar professores',
      subtitle: 'A conta líder pode aprovar, recusar ou revogar permissões.',
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHeading('Solicitações pendentes (${pending.length})'),
        if (pending.isEmpty) const EmptyState(
          icon: Icons.mark_email_read_outlined,
          title: 'Nenhum pedido pendente',
          subtitle: 'As novas solicitações aparecerão aqui.',
        ),
        for (final user in pending) ...[
          SoftCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user.name, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            Text('Solicitou acesso como professor.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 14),
            Wrap(spacing: 10, runSpacing: 10, children: [
              FilledButton.icon(
                onPressed: () => _decide(context, user.id, true),
                icon: const Icon(Icons.check),
                label: Text('Aprovar'),
              ),
              OutlinedButton.icon(
                onPressed: () => _decide(context, user.id, false),
                icon: const Icon(Icons.close),
                label: Text('Recusar'),
              ),
            ]),
          ])),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 25),
        SectionHeading('Professores autorizados (${professors.length})'),
        if (professors.isEmpty) Text('Nenhum professor autorizado ainda.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        for (final user in professors) ...[
          SoftCard(color: CampusColors.neutral, child: Row(children: [
            const CircleAvatar(backgroundColor: CampusColors.lavenderBlue,
              child: Icon(Icons.school_outlined, color: CampusColors.navy)),
            const SizedBox(width: 13),
            Expanded(child: Text(user.name, style: TextStyle(fontWeight: FontWeight.w600))),
            TextButton(onPressed: () async {
              await store.revokeProfessor(user.id);
              if (context.mounted) showInfo(context, 'Permissão revogada.');
            }, child: Text('Revogar')),
          ])),
          const SizedBox(height: 10),
        ],
      ]),
    );
  }

  Future<void> _decide(BuildContext context, String userId, bool approve) async {
    try {
      await store.decideRequest(userId, approve);
      if (context.mounted) showInfo(context, approve ? 'Professor aprovado.' : 'Solicitação recusada.');
    } on AppMessage catch (e) {
      if (context.mounted) showInfo(context, e.message);
    }
  }
}
