# ConnectVertix Online — instalação (Windows, Web e Android)

Esta versão **não funciona apenas abrindo o ZIP**. É necessário criar um projeto gratuito no Supabase para hospedar a autenticação, o PostgreSQL, o armazenamento privado de fotos e a sincronização entre dispositivos.

## 1. Crie o banco de dados online

1. Acesse https://supabase.com/dashboard e crie sua conta e um projeto novo.
2. Guarde a senha do **banco de dados** no seu gerenciador de senhas. Ela **não** vai para o Flutter nem será utilizada diretamente pelo aplicativo.
3. Entre em **SQL Editor**, clique em uma nova consulta, cole TODO o conteúdo de `supabase/schema.sql` e clique em **Run** uma única vez, em um projeto novo.
4. Em **Table Editor**, confirme que aparecem tabelas como `profiles`, `courses`, `rides`, `ride_bookings`, `notices`, `found_items`, `found_item_claims` etc. Em **Storage**, o bucket privado `found-items` deve existir.
5. Em **Authentication → Providers → Email**, mantenha o login por e-mail habilitado. É recomendado manter a confirmação de e-mail habilitada para uso real. Em testes, é possível usar o e-mail verdadeiro e concluir a confirmação recebida. A entrega desses e-mails depende das configurações/limites do Supabase.

> ATENÇÃO: não execute o SQL num banco com tabelas que você queira preservar sem antes revisar o esquema. Os usuários da versão local não migram automaticamente, pois o formato antigo não permite importação segura de credenciais.

## 2. Configure a URL e a chave pública do aplicativo

1. No painel do projeto Supabase, abra **Connect** ou **Settings → API Keys**.
2. Copie **Project URL** e a **publishable key** (ou chave pública `anon` legada se necessário).
3. Na pasta `supabase`, copie `config.example.json` com o nome `config.dev.json`.
4. Substitua os exemplos pelos valores do seu projeto:

```json
{
  "SUPABASE_URL": "https://seu-projeto.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_..."
}
```

É normal que a chave **publicável** esteja presente no APK: segurança real vem das políticas RLS no banco. **NUNCA use a chave `service_role`, `secret` ou a senha do banco no arquivo de configuração do Flutter.** Não envie `config.dev.json` para repositórios públicos por engano, ainda que a chave publicável não seja segredo.

## 3. Execute no navegador

Abra a pasta que contém `pubspec.yaml` no VS Code e execute:

```powershell
flutter pub get
flutter run -d chrome --web-port=8080 --dart-define-from-file=supabase/config.dev.json
```

Ou dê dois cliques em `rodar_web.bat`.

Se o app mostrar erro de permissão, verifique se executou `schema.sql` inteiro no projeto que corresponde à URL e à chave escolhidas.

## 4. Como configurar a conta líder de modo seguro

**Não há usuário ou senha de líder no código.** Primeiro crie uma conta pela tela de cadastro do próprio app, usando um e-mail seu e uma senha forte. Confirme o e-mail se exigido pelo Supabase.

Depois, no painel do Supabase, abra **Authentication → Users** e copie o **UUID** dessa conta. No **SQL Editor**, execute:

```sql
update public.profiles
set role='lider', request_status='aprovada', course=null
where id='SEU-UUID-DA-CONTA'::uuid;
```

Somente o administrador do projeto deve executar essa atualização. **Nunca forneça esse SQL, acesso ao painel do Supabase ou a senha da sua conta líder a alunos.** Saia e entre no app novamente ou atualize a página para carregar a nova permissão.

## 5. Teste a sincronização entre dois dispositivos

1. Cadastre uma conta `Aluno A` no primeiro dispositivo, com e-mail real.
2. No segundo dispositivo, entre com o mesmo e-mail e senha. A conta e seu curso serão recuperados do banco.
3. Cadastre um motorista em outra conta; ofereça uma carona.
4. A carona aparecerá no primeiro dispositivo, desde que ambos estejam online. Reserve-a e confirme que as vagas diminuíram no segundo. Duas reservas simultâneas da última vaga são impedidas por uma função transacional com bloqueio no Postgres.
5. Na conta líder, aprove uma solicitação de professor. O professor poderá publicar avisos por curso.
6. Nos Achados e perdidos, alguém posta um item com foto. O dono clica em **Sou o dono — solicitar retirada**; quem cadastrou aprova; depois de receber o objeto, o dono confirma. O item desaparece da lista pública. Não há verificação documental de propriedade: a entrega presencial deve ser conferida com cuidado.

## 6. Gere o APK Android

Instale Flutter e Android Studio com Android SDK e NDK configurados. Abra a pasta `ConnectVertix` e execute:

```powershell
flutter pub get
powershell -ExecutionPolicy Bypass -File preparar_android.ps1
flutter build apk --release --dart-define-from-file=supabase/config.dev.json
```

Ou dê dois cliques no arquivo `gerar_apk_android.bat`.

A etapa `preparar_android.ps1` cria o projeto Android se necessário e verifica se o AndroidManifest tem a permissão de INTERNET para funcionar no APK de produção.

O APK fica em `build/app/outputs/flutter-apk/app-release.apk`. Instale-o no seu próprio dispositivo Android para testar.

## 7. Importante

- Todos os módulos (cursos, professores, reservas, avisos, caronas, passageiros, eventos, itens e pedidos de retirada) são persistidos no PostgreSQL. Fotos ficam no Supabase Storage, em bucket privado, acessadas por URLs assinadas temporárias.
- Permissões não dependem dos botões: o servidor aplica regras RLS e funções transacionais, inclusive para administrador, professores, vagas e retirada de itens.
- O tema claro/escuro é preferência local; o restante é online.
- Sem internet, o login inicial e as operações que exigem o servidor não funcionarão. Não há modo offline de escrita.
- Os dados antigos do armazenamento local **não são transferidos automaticamente** para o banco.
- A configuração de e-mail (entrega, limite, domínio, possíveis restrições por padrão do serviço) deve ser validada antes de disponibilizar para outros alunos.
- RLS e autenticação reduzem riscos, mas o app é um projeto acadêmico; antes de uma implantação institucional, deve passar por testes de carga, revisão de segurança e aprovação da instituição.
- O Supabase tem camada gratuita com limites e eventual pausa por inatividade. Verifique https://supabase.com/pricing.
- Se o Flutter reclamar de NDK, instale pelo **Android Studio → SDK Manager → SDK Tools → NDK (Side by side)** a versão solicitada no erro.
