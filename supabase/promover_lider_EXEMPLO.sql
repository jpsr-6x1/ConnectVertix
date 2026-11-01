-- DEPOIS de cadastrar sua conta normal no aplicativo:
-- Supabase > Authentication > Users > copie o UUID da conta que voce controla.
-- Execute esta instrucao NO SQL EDITOR (nao no Flutter).
-- Substitua o UUID abaixo pelo UUID verdadeiro da sua conta:
update public.profiles
set role = 'lider', request_status = 'aprovada', course = null
where id = '00000000-0000-0000-0000-000000000000'::uuid;
-- Deve retornar exatamente a conta escolhida:
select id,display_name,role from public.profiles where role = 'lider';
