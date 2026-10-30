# ConnectVertix v1.3 — Flutter Web + Android

Aplicativo **demonstrativo acadêmico** para a Univértix. Visual inspirado na referência fornecida: azul da faculdade no tema claro, modo escuro com fundo preto e cartões escuros.

## Funcionalidades

- **Login e cadastro:** nome, senha e curso. O curso deve estar cadastrado pelo líder; usuários anteriores e seus cursos são migrados automaticamente.
- **Líder:** autoriza ou nega pedidos de professor; no **Perfil → Gerenciar cursos** pode **adicionar, renomear e remover cursos**; no **Perfil → Gerenciar laboratórios e salas** pode **adicionar, renomear e remover espaços**. Alterações de nomes de cursos atualizam contas e avisos; alterações de nomes de salas atualizam reservas. A exclusão de curso com alunos/avisos vinculados e de espaço com reservas é bloqueada. Cursos e espaços duplicados são bloqueados.
- **Reservas:** apenas professores/líder cadastram ou excluem reservas; todos veem os nomes de quem reservou cada sala e os horários, sem sobreposição.
- **Mural:** professores/líder publicam avisos gerais ou dirigidos a um curso; alunos veem os gerais e os do próprio curso.
- **Caronas:** a aba possui botão **Voltar ao início**. Em **Oferecer carona**, a origem é escolhida entre **Centro** e **Complexo**, o **destino é digitado livremente**, a **descrição do carro é obrigatória** e o **contato do motorista é opcional**. O contato informado aparece no anúncio aos usuários conectados. As vagas disponíveis diminuem ao reservar; cancelamento devolve a vaga. Aparecem os **nomes dos passageiros que reservaram**. O motorista não pode reservar a própria carona, e uma pessoa só pode reservar uma vaga por anúncio. Anúncios feitos em versões antigas continuam aparecendo, mesmo sem a descrição do carro.
- **Achados e perdidos:** imagem opcional do objeto, escolhida da galeria ou arquivos do dispositivo (Web/Android). As imagens são reduzidas para JPEG e armazenadas localmente; há limite de espaço. Quem cadastrou o item **ou o líder** pode tocar em **Confirmar retirada pelo dono**, informar quem retirou e confirmar *depois da entrega*. O item desaparece da lista de disponíveis, mas o registro da retirada fica guardado (sem a imagem para economizar espaço).
- **Eventos:** professores/líder criam e excluem anúncios; alunos acompanham.
- **Tema:** alternar em **Perfil → Tema escuro**. O fundo passa a ser preto (`#000000`) com cartões em tons de cinza escuro.

## Conta líder (SOMENTE PARA DEMONSTRAÇÃO)

- Usuário: `lider`
- Senha: `Vertix@2026`

**ATENÇÃO:** a autenticação é local e as senhas ficam no próprio dispositivo. Não use senhas reais nem dados pessoais sensíveis. Uma conta líder fixa no código não protege uma instalação pública.

## Rodar no navegador

1. Extraia o ZIP e abra **a pasta `ConnectVertix` que contém `pubspec.yaml`** no VS Code.
2. No terminal:

```powershell
flutter pub get
flutter run -d chrome --web-port=8080
```

A versão anterior usa a mesma chave de armazenamento. No **mesmo navegador, endereço e porta 8080**, os cadastros antigos devem continuar funcionando. **Não apague os dados do navegador** se quiser preservá-los.

## Criar um APK Android

Para gerar Android, instale/ajuste o Android SDK e o NDK pelo Android Studio (o erro do Visual Studio para Windows não interfere):

```powershell
flutter create --platforms=android .
flutter pub get
flutter build apk --release
```

O arquivo gerado fica em `build\app\outputs\flutter-apk\app-release.apk`. Também há `gerar_apk_android.bat` na pasta. O ZIP não contém uma pasta `android` fixa, pois ela é gerada para a versão Flutter instalada no computador.

## Testes

```powershell
flutter test
```

Os testes verificam aprovação de professores, avisos por curso, conflitos de horários, gestão de cursos/salas, vagas e identificação de passageiros, retirada de achados, persistência, campos da oferta de carona e o botão de voltar da aba.

## Limitações importantes (protótipo)

- O armazenamento é **local por navegador/dispositivo** (`shared_preferences`). Não sincroniza diferentes celulares. Reserva de vaga, aprovação de professores, avisos e retirada de objetos **não funcionam entre dispositivos distintos** sem um backend; portanto, ainda não é seguro para uso real pela faculdade.
- Fotos são compactadas e há limite local (~1,4 milhão de caracteres base64, compartilhados entre as imagens cadastradas). Para uma versão real, seriam usadas imagens em armazenamento remoto.
- A foto é selecionada da galeria/arquivos. Para tirar foto diretamente com a câmera, seria necessária uma alteração adicional na interface.
- O nome dos passageiros e o contato opcional do motorista são visíveis aos usuários conectados. **Não informe contato se não quiser compartilhá-lo.** Prefira combinar o encontro em locais públicos com pessoas conhecidas ou verificadas pela instituição. Evite endereços residenciais e dados pessoais sensíveis.

## Referência visual

Imagem original disponível em `design/referencia-visual.jpeg`.
