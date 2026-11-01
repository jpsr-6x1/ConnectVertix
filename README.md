# ConnectVertix — Versão Online (Supabase)

Aplicativo Flutter para a comunidade da Univértix, com contas de verdade e dados compartilhados em tempo real. Preserva as funcionalidades e a identidade visual da versão anterior.

**COMECE por [CONFIGURACAO_SUPABASE.md](CONFIGURACAO_SUPABASE.md).** Um projeto remoto precisa ser criado na sua conta Supabase antes de executar.

Contém:
- `supabase/schema.sql`: estrutura PostgreSQL, autenticação, RLS, funções transacionais e storage;
- `supabase/promover_lider_EXEMPLO.sql`: exemplo de configuração administrativa, sem credenciais;
- `supabase/config.example.json`: exemplo de URL e chave publicável;
- `rodar_web.bat` / `gerar_apk_android.bat`: scripts Windows;
- `preparar_android.ps1`: habilita a permissão de internet no APK;
- `lib/`: aplicativo Dart/Flutter.

Mudanças de arquitetura: login agora usa **e-mail e senha**, com nome de exibição e curso no perfil. Não há senha de líder no código. Papéis e permissões são impostos pelo banco. Os dados da versão offline não migram automaticamente.

Não inclua no repositório senhas, chaves secretas ou dados pessoais reais de alunos.


## Correção de compilação v5.1
O arquivo `lib/screens/module_pages.dart` importa agora `../models.dart` para reconhecer a classe `FoundItem`. Sem mudanças no banco de dados.
