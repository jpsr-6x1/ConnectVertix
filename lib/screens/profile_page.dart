import 'package:flutter/material.dart';
import '../app_store.dart';
import '../theme.dart';
import '../ui.dart';
import 'course_page.dart';
import 'permissions_page.dart';
import 'rooms_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.store});
  final AppStore store;

  @override Widget build(BuildContext context) => AnimatedBuilder(animation:store,builder:(context,_) {
    final user=store.currentUser;
    if(user==null) return const Center(child:CircularProgressIndicator());
    final mine=store.foundItems.where((item)=>item.authorId==user.id).toList()
      ..sort((a,b)=>b.createdAt.compareTo(a.createdAt));
    final muted=Theme.of(context).colorScheme.onSurfaceVariant;
    return CenterColumn(maxWidth:1040,child:ListView(padding:const EdgeInsets.fromLTRB(20,24,20,40),children:[
      const Text('Meu perfil',style:TextStyle(fontSize:30,fontWeight:FontWeight.w800)),
      const SizedBox(height:6),
      Text('Seus dados, preferências e publicações',style:TextStyle(color:muted)),
      const SizedBox(height:22),
      LayoutBuilder(builder:(context,limits) {
        final wide=limits.maxWidth>720;
        final profile=SoftCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[
            CircleAvatar(radius:35,backgroundColor:CampusColors.lavenderBlue,
              child:Text(user.name.isEmpty?'CV':user.name.substring(0,1).toUpperCase(),
                style:const TextStyle(color:CampusColors.navy,fontSize:26,fontWeight:FontWeight.w800))),
            const SizedBox(width:16),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(user.name,style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
              Text(user.isLeader?'Líder':user.canManage?'Professor':'Aluno',style:TextStyle(color:muted)),
            ])),
          ]),
          const SizedBox(height:18),
          DetailRow(icon:Icons.school_outlined,text:'Curso: ${user.course ?? 'Não informado'}'),
          DetailRow(icon:Icons.email_outlined,text:'E-mail: ${store.currentEmail ?? 'Não informado'}'),
          const SizedBox(height:18),
          OutlinedButton.icon(onPressed:()=>_editProfile(context),icon:const Icon(Icons.edit_outlined),label:const Text('Editar dados')),
          if(!user.isLeader) TextButton.icon(onPressed:()=>_open(context,CoursePage(store:store)),
            icon:const Icon(Icons.school_outlined),label:const Text('Alterar meu curso')),
        ]));
        final settings=SoftCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('Configurações',style:TextStyle(fontSize:20,fontWeight:FontWeight.w800)),
          const SizedBox(height:14),
          const Text('Aparência',style:TextStyle(fontWeight:FontWeight.w600)),
          const SizedBox(height:8),
          SegmentedButton<bool>(segments:const [
            ButtonSegment(value:false,icon:Icon(Icons.light_mode_outlined),label:Text('Claro')),
            ButtonSegment(value:true,icon:Icon(Icons.dark_mode_outlined),label:Text('Escuro')),
          ],selected:{store.darkMode},onSelectionChanged:(s)=>store.setDarkMode(s.first)),
          const SizedBox(height:20),
          Text('Tamanho do texto: ${(store.textScale*100).round()}%',style:const TextStyle(fontWeight:FontWeight.w600)),
          Row(children:[const Text('A',style:TextStyle(fontSize:13)),
            Expanded(child:Slider(value:store.textScale,min:.85,max:1.35,divisions:10,
              label:'${(store.textScale*100).round()}%',onChanged:(value)=>store.setTextScale(value))),
            const Text('A',style:TextStyle(fontSize:23))]),
          const SizedBox(height:8),
          OutlinedButton.icon(onPressed:()=>_changePassword(context),
            icon:const Icon(Icons.key_outlined),label:const Text('Alterar senha')),
          const SizedBox(height:5),
          Text('O tamanho escolhido também será aplicado aos outros módulos.',
            style:TextStyle(fontSize:12,color:muted)),
        ]));
        if(wide) return Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Expanded(child:profile),const SizedBox(width:18),Expanded(child:settings)
        ]);
        return Column(children:[profile,const SizedBox(height:16),settings]);
      }),
      const SizedBox(height:25),
      SectionHeading('Minhas publicações · Achados e perdidos',
        trailing:Text('${mine.length} publicação(ões)',style:TextStyle(color:muted,fontSize:12))),
      if(mine.isEmpty) const EmptyState(icon:Icons.search_off_outlined,
        title:'Você ainda não publicou objetos',subtitle:'Os itens encontrados cadastrados por você aparecerão aqui.'),
      for(final item in mine) ...[
        SoftCard(child:Row(children:[
          ClipRRect(borderRadius:BorderRadius.circular(12),child:item.imageUrl!=null
            ? Image.network(item.imageUrl!,height:62,width:62,fit:BoxFit.cover,
                errorBuilder:(_,__,___)=>const Icon(Icons.image_not_supported_outlined,size:44))
            : Container(width:62,height:62,color:CampusColors.lavenderBlue,
                child:const Icon(Icons.inventory_2_outlined,color:CampusColors.navy))),
          const SizedBox(width:14),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(item.name,style:const TextStyle(fontWeight:FontWeight.w700)),
            Text(item.location,style:TextStyle(color:muted,fontSize:12)),
            Text(item.isAvailable?'Disponível para retirada':'Retirado',
              style:TextStyle(fontWeight:FontWeight.bold,fontSize:12,
                color:item.isAvailable?const Color(0xFF16834B):muted)),
          ])),
          Text(formatDate(item.createdAt),style:TextStyle(fontSize:11,color:muted)),
        ])),
        const SizedBox(height:10),
      ],
      const SizedBox(height:19),
      OutlinedButton.icon(onPressed:()=>_open(context,PermissionsPage(store:store)),
        icon:const Icon(Icons.verified_user_outlined),label:Text(store.isLeader?'Gerenciar professores':'Permissão de professor')),
      if(store.isLeader) ...[
        const SizedBox(height:10),
        OutlinedButton.icon(onPressed:()=>_open(context,CoursesPage(store:store)),icon:const Icon(Icons.school_outlined),label:const Text('Gerenciar cursos')),
        const SizedBox(height:10),
        OutlinedButton.icon(onPressed:()=>_open(context,RoomsPage(store:store)),icon:const Icon(Icons.meeting_room_outlined),label:const Text('Gerenciar salas e laboratórios')),
      ],
      const SizedBox(height:15),
      OutlinedButton.icon(onPressed:store.logout,icon:const Icon(Icons.logout),label:const Text('Sair da conta')),
    ]));
  });

  void _open(BuildContext ctx,Widget page)=>Navigator.push(ctx,MaterialPageRoute<void>(builder:(_)=>page));

  Future<void> _editProfile(BuildContext context) async {
    final user=store.currentUser!;
    final name=TextEditingController(text:user.name);
    final email=TextEditingController(text:store.currentEmail);
    String? course=user.course;
    var saving=false;
    await showDialog<void>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,update)=>AlertDialog(
      title:const Text('Editar meus dados'),
      content:SizedBox(width:440,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:name,decoration:const InputDecoration(labelText:'Nome')),
        const SizedBox(height:12),
        TextField(controller:email,keyboardType:TextInputType.emailAddress,
          decoration:const InputDecoration(labelText:'E-mail')),
        const SizedBox(height:12),
        if(!user.isLeader) DropdownButtonFormField<String>(value:store.allCourses.contains(course)?course:null,
          isExpanded:true,decoration:const InputDecoration(labelText:'Curso'),
          items:[for(final item in store.allCourses) DropdownMenuItem(value:item,child:Text(item,overflow:TextOverflow.ellipsis))],
          onChanged:(value)=>update(()=>course=value)),
        const SizedBox(height:8),
        const Text('Se alterar o e-mail, pode ser necessário confirmar o novo endereço.',style:TextStyle(fontSize:12)),
      ]))),
      actions:[TextButton(onPressed:saving?null:()=>Navigator.pop(ctx),child:const Text('Cancelar')),
        FilledButton(onPressed:saving?null:() async {
          update(()=>saving=true);
          try {await store.updateMyProfile(name:name.text,course:course,email:email.text);
            if(ctx.mounted) Navigator.pop(ctx);
          } on AppMessage catch(e) {if(ctx.mounted) showInfo(ctx,e.message);update(()=>saving=false);}
        },child:const Text('Salvar'))],
    )));
    name.dispose();email.dispose();
  }

  Future<void> _changePassword(BuildContext context) async {
    final password=TextEditingController();
    final repeat=TextEditingController();
    bool busy=false;
    await showDialog<void>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,update)=>AlertDialog(
      title:const Text('Alterar senha'),
      content:SizedBox(width:390,child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:password,obscureText:true,decoration:const InputDecoration(labelText:'Nova senha (mín. 8 caracteres)')),
        const SizedBox(height:12),
        TextField(controller:repeat,obscureText:true,decoration:const InputDecoration(labelText:'Confirmar nova senha')),
      ])),
      actions:[TextButton(onPressed:busy?null:()=>Navigator.pop(ctx),child:const Text('Cancelar')),
        FilledButton(onPressed:busy?null:() async {
          if(password.text!=repeat.text) {showInfo(ctx,'As senhas não coincidem.');return;}
          update(()=>busy=true);
          try {await store.changePassword(password.text);
            if(ctx.mounted) Navigator.pop(ctx);
          } on AppMessage catch(e) {if(ctx.mounted) showInfo(ctx,e.message);update(()=>busy=false);}
        },child:const Text('Atualizar'))],
    )));
    password.dispose();repeat.dispose();
  }
}

/// Tela aberta após o usuário clicar no link de recuperação enviado por e-mail.
class PasswordRecoveryPage extends StatefulWidget {
  const PasswordRecoveryPage({super.key,required this.store});
  final AppStore store;
  @override State<PasswordRecoveryPage> createState()=>_PasswordRecoveryPageState();
}
class _PasswordRecoveryPageState extends State<PasswordRecoveryPage> {
  final password=TextEditingController();
  final repeat=TextEditingController();
  bool busy=false;
  @override void dispose(){password.dispose();repeat.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Scaffold(body:CenterColumn(maxWidth:450,
    child:ListView(shrinkWrap:true,padding:const EdgeInsets.all(25),children:[
      const Icon(Icons.lock_reset,size:54,color:CampusColors.navy),
      const SizedBox(height:16),
      const Text('Definir nova senha',textAlign:TextAlign.center,
        style:TextStyle(fontSize:25,fontWeight:FontWeight.bold)),
      const SizedBox(height:22),
      TextField(controller:password,obscureText:true,decoration:const InputDecoration(labelText:'Nova senha')),
      const SizedBox(height:12),
      TextField(controller:repeat,obscureText:true,decoration:const InputDecoration(labelText:'Confirmar nova senha')),
      const SizedBox(height:22),
      FilledButton(onPressed:busy?null:() async {
        if(password.text!=repeat.text){showInfo(context,'As senhas não coincidem.');return;}
        setState(()=>busy=true);
        try {await widget.store.changePassword(password.text);
          if(mounted) showInfo(context,'Senha atualizada.');
        } on AppMessage catch(e){if(mounted) showInfo(context,e.message);}
        finally{if(mounted)setState(()=>busy=false);}
      },child:const Text('Salvar nova senha')),
    ])));
}
