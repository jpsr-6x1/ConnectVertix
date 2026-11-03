import 'package:flutter/material.dart';
import '../app_store.dart';
import '../models.dart';
import '../theme.dart';
import '../ui.dart';

const agendaKinds = <String>['Prova','Trabalho','Feriado','Aula especial','Evento','Apresentação','Outro'];

Color agendaColor(String kind) => switch(kind) {
  'Prova' => const Color(0xFF2465C8),
  'Trabalho' => const Color(0xFF783EC9),
  'Feriado' => const Color(0xFFE03645),
  'Evento' => const Color(0xFF14945C),
  'Apresentação' => const Color(0xFFB44DB0),
  _ => const Color(0xFFDF8730),
};

class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key, required this.store});
  final AppStore store;
  @override State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  DateTime _month = DateTime(DateTime.now().year,DateTime.now().month);
  DateTime? _selected;
  String _filter = 'Todos';

  void _shift(int count) => setState(() {
    _month = DateTime(_month.year,_month.month+count);
    _selected = null;
  });
  bool _sameDate(DateTime a,DateTime b) => a.year==b.year&&a.month==b.month&&a.day==b.day;
  static const _months = <String>['Janeiro','Fevereiro','Março','Abril','Maio','Junho',
    'Julho','Agosto','Setembro','Outubro','Novembro','Dezembro'];
  String get _monthTitle => '${_months[_month.month-1]} de ${_month.year}';

  @override Widget build(BuildContext context) => AnimatedBuilder(
    animation:widget.store,builder:(context,_) {
      final records = widget.store.agendaItems.where((item) {
        if (_selected != null && !_sameDate(_selected!, item.date)) return false;
        if (_selected == null && (item.date.year != _month.year || item.date.month != _month.month)) return false;
        if (_filter=='Geral' && !item.isGeneral) return false;
        if (_filter=='Meu curso' && item.targetCourse != widget.store.currentUser?.course) return false;
        return true;
      }).toList()..sort((a,b) => a.date.compareTo(b.date));
      return LayoutBuilder(builder:(context,limits) {
        final wide = limits.maxWidth >= 850;
        final calendar = _calendar(context);
        final list = _entries(context,records);
        return SingleChildScrollView(
          padding:EdgeInsets.symmetric(horizontal:wide?32:18,vertical:25),
          child:CenterColumn(maxWidth:1150,child:Column(
            crossAxisAlignment:CrossAxisAlignment.start,children:[
              Wrap(alignment:WrapAlignment.spaceBetween,crossAxisAlignment:WrapCrossAlignment.center,
                spacing:16,runSpacing:12,children:[
                  Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                    const Text('Agenda acadêmica',style:TextStyle(fontSize:29,fontWeight:FontWeight.w800)),
                    const SizedBox(height:5),
                    Text('Provas, trabalhos, feriados e atividades do campus',
                      style:TextStyle(color:Theme.of(context).colorScheme.onSurfaceVariant)),
                  ]),
                  if(widget.store.canManage) FilledButton.icon(
                    onPressed:()=>_newAgendaEntry(context), icon:const Icon(Icons.add),
                    label:const Text('Novo item')),
                ]),
              const SizedBox(height:22),
              if(wide) Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Expanded(flex:5,child:calendar), const SizedBox(width:19), Expanded(flex:5,child:list),
              ]) else Column(children:[calendar,const SizedBox(height:20),list]),
            ],
          )),
        );
      });
    });

  Widget _calendar(BuildContext context) {
    final first = DateTime(_month.year,_month.month,1);
    final pad = first.weekday % 7;
    final days = DateTime(_month.year,_month.month+1,0).day;
    final count = ((pad+days+6)~/7)*7;
    final visibleItems = widget.store.agendaItems;
    final dark = Theme.of(context).brightness==Brightness.dark;
    final dates = List.generate(count,(index)=>DateTime(_month.year,_month.month,index-pad+1));
    return SoftCard(child:Column(children:[
      Row(children:[
        IconButton(tooltip:'Mês anterior',onPressed:()=>_shift(-1),icon:const Icon(Icons.chevron_left)),
        Expanded(child:Text(_monthTitle,textAlign:TextAlign.center,
          style:const TextStyle(fontSize:19,fontWeight:FontWeight.w800))),
        IconButton(tooltip:'Próximo mês',onPressed:()=>_shift(1),icon:const Icon(Icons.chevron_right)),
      ]),
      const SizedBox(height:12),
      Row(children:[for(final label in ['Dom','Seg','Ter','Qua','Qui','Sex','Sáb'])
        Expanded(child:Text(label,textAlign:TextAlign.center,style:TextStyle(fontSize:12,fontWeight:FontWeight.w700)))]),
      const SizedBox(height:8),
      GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),
        gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:7,childAspectRatio:1.1),
        itemCount:dates.length,itemBuilder:(ctx,i) {
          final day = dates[i];
          final active = _selected != null && _sameDate(day,_selected!);
          final today = _sameDate(day,DateTime.now());
          final colors = visibleItems.where((e)=>_sameDate(e.date,day)).take(3).map((e)=>agendaColor(e.kind)).toList();
          return InkWell(onTap:()=>setState(() => _selected = active ? null : day),
            borderRadius:BorderRadius.circular(12),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
              Container(width:32,height:31,alignment:Alignment.center,
                decoration:BoxDecoration(color:active?CampusColors.navy:(today ? (dark?const Color(0xFF203858):const Color(0xFFDDE9FF)):Colors.transparent),
                  borderRadius:BorderRadius.circular(12)),
                child:Text('${day.day}',style:TextStyle(fontSize:13,fontWeight:active||today?FontWeight.w800:FontWeight.w500,
                  color:active?Colors.white:(day.month!=_month.month?Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(.48):null)))),
              const SizedBox(height:3),
              Row(mainAxisAlignment:MainAxisAlignment.center,children:[for(final color in colors) Padding(
                padding:const EdgeInsets.symmetric(horizontal:1),child:Container(width:4,height:4,decoration:BoxDecoration(color:color,shape:BoxShape.circle)))])
            ]));
        }),
      const SizedBox(height:10),
      Wrap(spacing:12,runSpacing:8,children:[for(final kind in agendaKinds.take(6))
        Row(mainAxisSize:MainAxisSize.min,children:[Container(width:8,height:8,decoration:BoxDecoration(color:agendaColor(kind),shape:BoxShape.circle)),
          const SizedBox(width:5),Text(kind,style:const TextStyle(fontSize:11))])]),
      if(_selected!=null) TextButton.icon(onPressed:()=>setState(()=>_selected=null),
        icon:const Icon(Icons.clear,size:17),label:const Text('Mostrar todos os dias')),
    ]));
  }

  Widget _entries(BuildContext context,List<AgendaItem> entries) => SoftCard(
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('Atividades',style:TextStyle(fontWeight:FontWeight.w800,fontSize:20)),
      const SizedBox(height:12),
      Wrap(spacing:8,children:[for(final option in ['Todos','Geral','Meu curso'])
        ChoiceChip(label:Text(option),selected:_filter==option,onSelected:(_)=>setState(()=>_filter=option))]),
      const SizedBox(height:12),
      if(entries.isEmpty) const Padding(padding:EdgeInsets.symmetric(vertical:28),
        child:Center(child:Text('Nenhuma atividade para este filtro.'))),
      for(final item in entries) ...[
        const Divider(height:14),
        Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
          CircleAvatar(backgroundColor:agendaColor(item.kind).withOpacity(.14),
            child:Icon(_kindIcon(item.kind),color:agendaColor(item.kind))),
          const SizedBox(width:12),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(item.title,style:const TextStyle(fontSize:15,fontWeight:FontWeight.w700)),
            Text('${formatDate(item.date)}${item.time==null||item.time!.isEmpty?'':' · ${item.time}'} · ${item.kind}',
              style:TextStyle(fontSize:12,color:Theme.of(context).colorScheme.onSurfaceVariant)),
            if(item.description.isNotEmpty) Padding(padding:const EdgeInsets.only(top:4),child:Text(item.description)),
            const SizedBox(height:7),
            Text(item.targetCourse ?? 'Geral',style:TextStyle(fontSize:12,fontWeight:FontWeight.bold,color:agendaColor(item.kind))),
          ])),
          if(widget.store.canManage && (widget.store.isLeader || widget.store.currentUser?.id==item.authorId))
            IconButton(tooltip:'Excluir atividade',icon:const Icon(Icons.delete_outline),onPressed:() async {
              if(!await confirmDelete(context) || !context.mounted) return;
              try {await widget.store.removeAgendaItem(item.id);} on AppMessage catch(e) {if(context.mounted) showInfo(context,e.message);}
            }),
        ]),
      ]
    ]),
  );

  IconData _kindIcon(String kind) => switch(kind) {
    'Prova' => Icons.assignment_outlined,
    'Trabalho' => Icons.folder_outlined,
    'Feriado' => Icons.celebration_outlined,
    'Evento' => Icons.event_outlined,
    'Apresentação' => Icons.present_to_all_outlined,
    _ => Icons.calendar_today_outlined,
  };

  Future<void> _newAgendaEntry(BuildContext context) async {
    final title=TextEditingController();
    final description=TextEditingController();
    DateTime date=_selected ?? DateTime.now();
    TimeOfDay? time;
    String kind='Prova';
    String target='__all__';
    bool saving=false;
    await showDialog<void>(context:context,builder:(ctx) => StatefulBuilder(builder:(ctx,update) => AlertDialog(
      title:const Text('Nova atividade na agenda'),
      content:SizedBox(width:440,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:title,maxLength:180,decoration:const InputDecoration(labelText:'Título *')),
        const SizedBox(height:10),
        DropdownButtonFormField<String>(value:kind,decoration:const InputDecoration(labelText:'Tipo'),
          items:[for(final value in agendaKinds) DropdownMenuItem(value:value,child:Text(value))],onChanged:(value)=>update(()=>kind=value??kind)),
        const SizedBox(height:10),
        DropdownButtonFormField<String>(value:target,decoration:const InputDecoration(labelText:'Destinado ao curso / turma'),
          items:[const DropdownMenuItem(value:'__all__',child:Text('Geral — todos os cursos')),
            for(final value in widget.store.allCourses) DropdownMenuItem(value:value,child:Text(value,overflow:TextOverflow.ellipsis))],
          onChanged:(value)=>update(()=>target=value??target)),
        const SizedBox(height:10),
        OutlinedButton.icon(icon:const Icon(Icons.calendar_month),label:Text('Data: ${formatDate(date)}'),onPressed:() async {
          final choice=await showDatePicker(context:ctx,firstDate:DateTime(2020),lastDate:DateTime(2100),
            initialDate:date,locale:const Locale('pt','BR'));
          if(choice!=null) update(()=>date=choice);
        }),
        OutlinedButton.icon(icon:const Icon(Icons.schedule),label:Text(time==null?'Horário (opcional)':time!.format(ctx)),onPressed:() async {
          final choice=await showTimePicker(context:ctx,initialTime:time??const TimeOfDay(hour:19,minute:0));
          if(choice!=null) update(()=>time=choice);
        }),
        const SizedBox(height:10),
        TextField(controller:description,maxLines:3,decoration:const InputDecoration(labelText:'Descrição (opcional)')),
      ]))),
      actions:[TextButton(onPressed:saving?null:()=>Navigator.pop(ctx),child:const Text('Cancelar')),
        FilledButton(onPressed:saving?null:() async {
          if(title.text.trim().isEmpty) {showInfo(ctx,'Informe o título.');return;}
          update(()=>saving=true);
          try {
            await widget.store.addAgendaItem(title:title.text,kind:kind,date:date,
              description:description.text,targetCourse:target=='__all__'?null:target,
              time:time==null?null:'${time!.hour.toString().padLeft(2,'0')}:${time!.minute.toString().padLeft(2,'0')}');
            if(ctx.mounted) Navigator.pop(ctx);
          } on AppMessage catch(e) {if(ctx.mounted) showInfo(ctx,e.message);update(()=>saving=false);}
        },child:const Text('Publicar'))],
    )));
    // Os controladores não precisam sobreviver à rota do formulário.
    title.dispose();description.dispose();
  }
}
