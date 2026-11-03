import 'package:flutter/material.dart';
import '../app_store.dart';
import '../models.dart';
import '../theme.dart';
import '../ui.dart';
import 'agenda_page.dart';
import 'module_pages.dart';
import 'permissions_page.dart';
import 'profile_page.dart';

class ConnectVertixMark extends StatelessWidget {
  const ConnectVertixMark({super.key,this.size=34});
  final double size;
  @override Widget build(BuildContext context)=>SizedBox(width:size,height:size,
    child:CustomPaint(painter:_VertixMarkPainter()));
}
class _VertixMarkPainter extends CustomPainter {
  @override void paint(Canvas canvas, Size size) {
    final scale=Size(size.width,size.height);
    final blue=Paint()..color=CampusColors.navy;
    final red=Paint()..color=CampusColors.red;
    final left=Path()
      ..moveTo(scale.width*.04,scale.height*.13)
      ..lineTo(scale.width*.31,scale.height*.13)
      ..lineTo(scale.width*.55,scale.height*.69)
      ..lineTo(scale.width*.69,scale.height*.42)
      ..lineTo(scale.width*.85,scale.height*.42)
      ..lineTo(scale.width*.55,scale.height*.98)
      ..close();
    final right=Path()
      ..moveTo(scale.width*.60,scale.height*.30)
      ..lineTo(scale.width*.73,scale.height*.08)
      ..lineTo(scale.width*.98,scale.height*.08)
      ..lineTo(scale.width*.73,scale.height*.55)
      ..close();
    canvas.drawPath(left,blue);
    canvas.drawPath(right,red);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate)=>false;
}

class ConnectVertixLogo extends StatelessWidget {
  const ConnectVertixLogo({super.key,this.large=false});
  final bool large;
  @override Widget build(BuildContext context) => Row(mainAxisSize:MainAxisSize.min,children:[
    ConnectVertixMark(size:large?43:32),
    const SizedBox(width:9),
    Text.rich(TextSpan(children:[
      TextSpan(text:'Connect',style:TextStyle(color:Theme.of(context).brightness==Brightness.dark?Colors.white:CampusColors.navy)),
      const TextSpan(text:'Vertix',style:TextStyle(color:CampusColors.red)),
    ]),style:TextStyle(fontSize:large?27:20,fontWeight:FontWeight.w900)),
  ]);
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key,required this.store});
  final AppStore store;
  @override State<DashboardPage> createState()=>_DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _tab=0;
  void _open(Widget page) => Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>page));
  void _select(int tab)=>setState(()=>_tab=tab);

  @override Widget build(BuildContext context) => LayoutBuilder(builder:(context,constraints){
    final desktop=constraints.maxWidth>=900;
    final body=IndexedStack(index:_tab,children:[
      _home(),AgendaPage(store:widget.store),
      RidePage(store:widget.store,embedded:true,onBack:()=>_select(0)),
      EventsPage(store:widget.store),ProfilePage(store:widget.store),
    ]);
    return Scaffold(
      body:SafeArea(child:desktop ? Row(children:[
        _sidebar(),
        Expanded(child:body),
      ]) : body),
      bottomNavigationBar:desktop?null:_bottomNav(),
    );
  });

  Widget _sidebar() {
    final dark=Theme.of(context).brightness==Brightness.dark;
    return Container(width:238,padding:const EdgeInsets.fromLTRB(14,24,14,14),
      decoration:BoxDecoration(color:dark?const Color(0xFF0C1019):Colors.white,
        border:Border(right:BorderSide(color:dark?const Color(0xFF202A3A):CampusColors.line))),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Padding(padding:const EdgeInsets.fromLTRB(8,4,0,29),child:ConnectVertixLogo()),
        _sideItem(Icons.home_outlined,'Início',0),
        _sideItem(Icons.calendar_today_outlined,'Reservas',null,()=>_open(ReservationPage(store:widget.store))),
        _sideItem(Icons.campaign_outlined,'Mural de avisos',null,()=>_open(NoticePage(store:widget.store))),
        _sideItem(Icons.search_outlined,'Achados e perdidos',null,()=>_open(FoundPage(store:widget.store))),
        _sideItem(Icons.directions_car_outlined,'Caronas',2),
        _sideItem(Icons.confirmation_num_outlined,'Eventos',3),
        _sideItem(Icons.event_note_outlined,'Agenda',1),
        _sideItem(Icons.person_outline,'Perfil',4),
        const Spacer(),
        const Divider(),
        _sideItem(Icons.verified_user_outlined,'Permissões',null,()=>_open(PermissionsPage(store:widget.store))),
        _sideItem(Icons.logout,'Sair',null,()=>widget.store.logout()),
      ]));
  }

  Widget _sideItem(IconData icon,String label,int? tab,[VoidCallback? action]){
    final selected=tab!=null&&tab==_tab;
    final dark=Theme.of(context).brightness==Brightness.dark;
    return Padding(padding:const EdgeInsets.symmetric(vertical:2),child:Material(
      color:selected?(dark?CampusColors.red:CampusColors.navy):Colors.transparent,
      borderRadius:BorderRadius.circular(12),child:InkWell(borderRadius:BorderRadius.circular(12),
      onTap:action??()=>_select(tab??0),child:Padding(padding:const EdgeInsets.symmetric(horizontal:12,vertical:13),
      child:Row(children:[Icon(icon,size:21,color:selected?Colors.white:null),const SizedBox(width:11),
        Expanded(child:Text(label,style:TextStyle(fontWeight:selected?FontWeight.w700:FontWeight.w500,
          color:selected?Colors.white:null)))]))),
    ));
  }

  Widget _bottomNav(){
    final dark=Theme.of(context).brightness==Brightness.dark;
    return Container(
      decoration:BoxDecoration(color:dark?const Color(0xFF10141C):Colors.white,
        border:Border(top:BorderSide(color:dark?const Color(0xFF232C3B):CampusColors.line))),
      child:SafeArea(top:false,child:NavigationBar(height:69,
        labelBehavior:NavigationDestinationLabelBehavior.alwaysShow,
        backgroundColor:Colors.transparent,indicatorColor:dark?const Color(0xFF692233):CampusColors.lavenderBlue,
        selectedIndex:_tab,
        onDestinationSelected:_select,destinations:const [
          NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'Início'),
          NavigationDestination(icon:Icon(Icons.event_note_outlined),selectedIcon:Icon(Icons.event_note),label:'Agenda'),
          NavigationDestination(icon:Icon(Icons.directions_car_outlined),selectedIcon:Icon(Icons.directions_car),label:'Caronas'),
          NavigationDestination(icon:Icon(Icons.confirmation_num_outlined),selectedIcon:Icon(Icons.confirmation_num),label:'Eventos'),
          NavigationDestination(icon:Icon(Icons.person_outline),selectedIcon:Icon(Icons.person),label:'Perfil'),
        ])),
    );
  }

  Widget _home(){
    final store=widget.store;
    final dark=Theme.of(context).brightness==Brightness.dark;
    final user=store.currentUser;
    final upcoming=store.events.where((e)=>!e.date.isBefore(DateTime(DateTime.now().year,DateTime.now().month,DateTime.now().day))).toList()
      ..sort((a,b)=>a.date.compareTo(b.date));
    final next=upcoming.isEmpty?null:upcoming.first;
    final notices=store.visibleNotices.toList()..sort((a,b)=>b.createdAt.compareTo(a.createdAt));
    final agenda=store.agendaItems.where((e)=>!e.date.isBefore(DateTime(DateTime.now().year,DateTime.now().month,DateTime.now().day))).toList()
      ..sort((a,b)=>a.date.compareTo(b.date));
    return CenterColumn(maxWidth:1250,child:ListView(padding:const EdgeInsets.fromLTRB(20,22,20,45),children:[
      Row(children:[
        if(MediaQuery.sizeOf(context).width<900) ...[
          CircleAvatar(backgroundColor:CampusColors.lavenderBlue,
            child:Text(user?.name.isNotEmpty==true?user!.name[0].toUpperCase():'CV',style:const TextStyle(color:CampusColors.navy))),
          const SizedBox(width:9),
          const Expanded(child:ConnectVertixLogo()),
        ] else const Expanded(child:ConnectVertixLogo()),
        IconButton(tooltip:'Permissão de professor',onPressed:()=>_open(PermissionsPage(store:store)),
          icon:Badge(isLabelVisible:store.isLeader&&store.pendingRequests.isNotEmpty,
            child:const Icon(Icons.admin_panel_settings_outlined))),
        IconButton(tooltip:'Avisos',onPressed:()=>_open(NoticePage(store:store)),
          icon:Badge(isLabelVisible:notices.isNotEmpty,child:const Icon(Icons.notifications_none_outlined))),
      ]),
      const SizedBox(height:23),
      Text('${getGreeting()} ${user?.name.split(' ').first ?? 'Aluno'}!',
        style:const TextStyle(fontSize:27,fontWeight:FontWeight.w800)),
      const SizedBox(height:3),
      Text('Univértix · Matipó',style:TextStyle(color:Theme.of(context).colorScheme.onSurfaceVariant)),
      const SizedBox(height:21),
      EventHeroBanner(event:next,onOpenEvents:()=>_select(3)),
      const SizedBox(height:25),
      const SectionHeading('Acesso rápido'),
      LayoutBuilder(builder:(context,box){
        final columns=box.maxWidth>=1050?6:box.maxWidth>=650?3:2;
        return GridView.count(physics:const NeverScrollableScrollPhysics(),shrinkWrap:true,
          crossAxisCount:columns,crossAxisSpacing:11,mainAxisSpacing:11,
          childAspectRatio: columns == 2 ? 0.95 : (columns == 3 ? 1.30 : 1.03),
          children:[
            _module(Icons.calendar_month_outlined,'Reservas','Laboratórios e salas',const Color(0xFFDCE8FF),CampusColors.navy,
              ()=>_open(ReservationPage(store:store))),
            _module(Icons.campaign_outlined,'Mural de avisos','Recados da coordenação',const Color(0xFFFFE5E7),CampusColors.red,
              ()=>_open(NoticePage(store:store))),
            _module(Icons.search_outlined,'Achados e perdidos','Itens encontrados',const Color(0xFFDDF6E8),const Color(0xFF137544),
              ()=>_open(FoundPage(store:store))),
            _module(Icons.directions_car_outlined,'Caronas','Caronas entre unidades',const Color(0xFFEDE1FE),const Color(0xFF6832AD),
              ()=>_select(2)),
            _module(Icons.confirmation_num_outlined,'Eventos','Programação',const Color(0xFFDCEAFE),const Color(0xFF1761B6),
              ()=>_select(3)),
            _module(Icons.event_note_outlined,'Agenda','Calendário acadêmico',const Color(0xFFFFE6DE),CampusColors.red,
              ()=>_select(1)),
          ]);
      }),
      const SizedBox(height:28),
      LayoutBuilder(builder:(context,bounds){
        final wide=bounds.maxWidth>740;
        final left=_listBox('Avisos recentes',notices.take(3).map((n)=>(_noticeIcon(n),n.title,n.message)).toList(),
          ()=>_open(NoticePage(store:store)));
        final right=_listBox('Próximos itens da agenda',agenda.take(3).map((a)=>(Icons.event_outlined,a.title,
          '${formatDate(a.date)} · ${a.targetCourse??'Geral'}')).toList(),()=>_select(1));
        return wide?Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Expanded(child:left),const SizedBox(width:15),Expanded(child:right)]):Column(children:[left,const SizedBox(height:15),right]);
      }),
      if(dark) const SizedBox(height:2),
    ]));
  }

  IconData _noticeIcon(Notice n)=>Icons.campaign_outlined;

  Widget _module(IconData icon,String title,String subtitle,Color lightColor,Color accent,VoidCallback tap){
    final dark=Theme.of(context).brightness==Brightness.dark;
    return Material(color:dark?Color.lerp(accent,const Color(0xFF101722),.82):lightColor,
      borderRadius:BorderRadius.circular(17),child:InkWell(onTap:tap,borderRadius:BorderRadius.circular(17),
      child:Padding(padding:const EdgeInsets.all(13),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Icon(icon,color:dark?Color.lerp(accent,Colors.white,.45):accent,size:27),
        const Spacer(),
        Text(title,maxLines:2,overflow:TextOverflow.ellipsis,
          style:const TextStyle(fontWeight:FontWeight.w800,fontSize:14)),
        Text(subtitle,maxLines:2,overflow:TextOverflow.ellipsis,
          style:const TextStyle(fontSize:11)),
      ]))));
  }

  Widget _listBox(String heading,List<(IconData,String,String)> items,VoidCallback tap)=>
    SoftCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Expanded(child:Text(heading,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w800))),
        TextButton(onPressed:tap,child:const Text('Ver todos'))]),
      if(items.isEmpty) Padding(padding:const EdgeInsets.symmetric(vertical:23),
        child:Text('Nenhuma publicação por enquanto.',style:TextStyle(color:Theme.of(context).colorScheme.onSurfaceVariant))),
      for(final item in items) ...[
        const Divider(height:12),
        InkWell(onTap:tap,child:Padding(padding:const EdgeInsets.symmetric(vertical:7),
          child:Row(children:[CircleAvatar(radius:20,backgroundColor:CampusColors.lavenderBlue,
            child:Icon(item.$1,color:CampusColors.navy,size:21)),const SizedBox(width:12),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(item.$2,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w700)),
              Text(item.$3,maxLines:1,overflow:TextOverflow.ellipsis,
                style:TextStyle(fontSize:12,color:Theme.of(context).colorScheme.onSurfaceVariant)),
            ])),const Icon(Icons.chevron_right,size:19)]))),
      ],
    ]));
}

/// Banner responsivo: a arte decorativa não é desenhada em telas estreitas.
/// Em telas largas, o texto tem uma área própria, livre da forma vermelha.
class EventHeroBanner extends StatelessWidget {
  const EventHeroBanner({super.key, required this.event, required this.onOpenEvents});

  final CampusEvent? event;
  final VoidCallback onOpenEvents;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // O desenho só aparece quando existe espaço suficiente para texto e arte.
      final showDecoration = constraints.maxWidth >= 800;
      final textMaxWidth = showDecoration ? constraints.maxWidth - 250 : constraints.maxWidth;

      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF092D6C), Color(0xFF1759B0), Color(0xFF0A2454)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              if (showDecoration)
                Positioned(
                  key: const Key('event_banner_decoration'),
                  right: -52,
                  top: -90,
                  child: IgnorePointer(
                    child: Transform.rotate(
                      angle: .45,
                      child: Container(
                        width: 165,
                        height: 280,
                        decoration: BoxDecoration(
                          color: CampusColors.red,
                          borderRadius: BorderRadius.circular(48),
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 25, 24, 26),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: textMaxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('PRÓXIMO EVENTO', style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      )),
                      const SizedBox(height: 9),
                      Text(
                        event?.title ?? 'Acompanhe os próximos eventos',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        event == null
                            ? 'Confira a programação dos próximos eventos'
                            : '${formatDate(event!.date)} · ${event!.time}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 17),
                      FilledButton.icon(
                        onPressed: onOpenEvents,
                        style: FilledButton.styleFrom(
                          backgroundColor: CampusColors.red,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.arrow_forward, size: 17),
                        label: const Text('Ver programação'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
