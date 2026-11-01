-- ConnectVertix: executar uma vez no SQL Editor de um projeto Supabase novo.
-- Todas as permissoes sensiveis sao aplicadas no banco, nunca no Flutter.
create extension if not exists pgcrypto;
create extension if not exists btree_gist;

create table public.courses (
  name text primary key check (length(btrim(name)) between 3 and 120)
);
create unique index courses_name_lower on public.courses (lower(name));
create table public.rooms (
  name text primary key check (length(btrim(name)) between 3 and 120)
);
create unique index rooms_name_lower on public.rooms (lower(name));

insert into public.courses(name) values
 ('Ciência da Computação'),('Administração'),('Direito'),('Enfermagem'),('Engenharia Civil'),('Psicologia'),('Outros');
insert into public.rooms(name) values
 ('Laboratório de Informática 1'),('Laboratório de Informática 2'),('Sala 101'),('Sala 102'),('Auditório');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (length(btrim(display_name)) between 3 and 100),
  course text references public.courses(name) on update cascade on delete restrict,
  role text not null default 'aluno' check (role in ('aluno','professor','lider')),
  request_status text not null default 'nenhuma'
     check (request_status in ('nenhuma','pendente','aprovada','recusada')),
  created_at timestamptz not null default now()
);

create or replace function public.is_leader() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.profiles
    where id = (select auth.uid()) and role = 'lider');
$$;
create or replace function public.is_professor() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.profiles
    where id = (select auth.uid()) and role in ('professor','lider'));
$$;

create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles(id,display_name,course)
  values(new.id, coalesce(nullif(btrim(new.raw_user_meta_data->>'display_name'),''), 'Novo aluno'),
    nullif(new.raw_user_meta_data->>'course',''));
  return new;
end;
$$;
create trigger connectvertix_create_profile after insert on auth.users
for each row execute function public.handle_new_user();

create table public.reservations (
  id uuid primary key default gen_random_uuid(),
  room text not null references public.rooms(name) on update cascade on delete restrict,
  on_date date not null,
  start_minutes integer not null check (start_minutes between 0 and 1439),
  end_minutes integer not null check (end_minutes between 1 and 1440 and end_minutes > start_minutes),
  note text not null default '',
  author_id uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  constraint reservation_no_overlap exclude using gist
   (room with =, on_date with =, int4range(start_minutes,end_minutes,'[)') with &&)
);
create table public.notices (
  id uuid primary key default gen_random_uuid(),
  title text not null check (length(btrim(title)) > 0),
  message text not null check (length(btrim(message)) > 0),
  target_course text references public.courses(name) on update cascade on delete restrict,
  author_id uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);
create table public.found_items (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(btrim(name)) > 0),
  description text not null default '',
  location text not null check (length(btrim(location)) > 0),
  image_path text,
  author_id uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  retrieved_at timestamptz,
  retrieved_by_id uuid references public.profiles(id)
);
create table public.found_item_claims (
  item_id uuid not null references public.found_items(id) on delete cascade,
  claimant_id uuid not null references public.profiles(id),
  status text not null default 'pendente' check (status in ('pendente','aprovada','recusada')),
  created_at timestamptz not null default now(),
  primary key(item_id,claimant_id)
);
create unique index one_approved_claim_per_item on public.found_item_claims(item_id)
  where status = 'aprovada';
create table public.rides (
  id uuid primary key default gen_random_uuid(),
  origin text not null check (origin in ('Centro','Complexo')),
  destination text not null check (length(btrim(destination)) > 0),
  ride_date date not null,
  ride_time text not null,
  seats integer not null check (seats between 1 and 4),
  meeting_point text not null check (length(btrim(meeting_point)) > 0),
  vehicle_description text not null check (length(btrim(vehicle_description)) > 0),
  contact text,
  author_id uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);
create table public.ride_bookings (
  ride_id uuid not null references public.rides(id) on delete cascade,
  user_id uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  primary key(ride_id,user_id)
);
create table public.events (
  id uuid primary key default gen_random_uuid(),
  title text not null check (length(btrim(title)) > 0),
  description text not null default '',
  event_date date not null,
  event_time text not null,
  location text not null,
  author_id uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);

-- RLS por tabela, incluindo conteudo segmentado por curso.
do $$ declare t text; begin
  foreach t in array array['courses','rooms','profiles','reservations','notices',
    'found_items','found_item_claims','rides','ride_bookings','events'] loop
    execute format('alter table public.%I enable row level security',t);
  end loop;
end $$;

create policy course_read on public.courses for select to anon,authenticated using(true);
create policy course_leader_insert on public.courses for insert to authenticated
 with check(public.is_leader());
create policy course_leader_update on public.courses for update to authenticated
 using(public.is_leader()) with check(public.is_leader());
create policy course_leader_delete on public.courses for delete to authenticated
 using(public.is_leader());
create policy rooms_read on public.rooms for select to authenticated using(true);
create policy rooms_insert on public.rooms for insert to authenticated with check(public.is_leader());
create policy rooms_update on public.rooms for update to authenticated using(public.is_leader()) with check(public.is_leader());
create policy rooms_delete on public.rooms for delete to authenticated using(public.is_leader());
create policy profiles_read on public.profiles for select to authenticated using(true);
-- Apenas o campo course pode ser alterado pelo usuario. role e request_status sao protegidos.
revoke update on public.profiles from anon,authenticated;
grant update(course) on public.profiles to authenticated;
create policy profile_course_update on public.profiles for update to authenticated
 using(id = (select auth.uid())) with check(id = (select auth.uid()));

create policy reservations_read on public.reservations for select to authenticated using(true);
create policy reservations_add on public.reservations for insert to authenticated
 with check(author_id = (select auth.uid()) and public.is_professor());
create policy reservations_delete on public.reservations for delete to authenticated
 using(public.is_professor());
create policy notices_read on public.notices for select to authenticated
 using (public.is_professor() or target_course is null or target_course =
   (select p.course from public.profiles p where p.id = (select auth.uid())));
create policy notices_add on public.notices for insert to authenticated
 with check(author_id = (select auth.uid()) and public.is_professor());
create policy notices_delete on public.notices for delete to authenticated using(public.is_professor());
create policy found_read on public.found_items for select to authenticated using(true);
create policy found_add on public.found_items for insert to authenticated
 with check(author_id = (select auth.uid()) and retrieved_at is null and retrieved_by_id is null);
create policy found_delete on public.found_items for delete to authenticated
 using(author_id = (select auth.uid()) or public.is_leader());
create policy claims_read on public.found_item_claims for select to authenticated
 using(claimant_id = (select auth.uid()) or public.is_leader() or exists(
  select 1 from public.found_items f where f.id = item_id and f.author_id = (select auth.uid())));
create policy rides_read on public.rides for select to authenticated using(true);
create policy rides_add on public.rides for insert to authenticated
 with check(author_id = (select auth.uid()));
create policy rides_delete on public.rides for delete to authenticated
 using(author_id = (select auth.uid()) or public.is_leader());
create policy bookings_read on public.ride_bookings for select to authenticated using(true);
create policy events_read on public.events for select to authenticated using(true);
create policy events_add on public.events for insert to authenticated
 with check(author_id = (select auth.uid()) and public.is_professor());
create policy events_delete on public.events for delete to authenticated using(public.is_professor());

-- Funcoes atomicas: a UI nunca concede cargo, vaga ou entrega por conta propria.
create or replace function public.request_professor() returns void language plpgsql
 security definer set search_path = '' as $$
begin
  update public.profiles set request_status='pendente'
    where id=auth.uid() and role='aluno' and request_status <> 'pendente';
  if not found then raise exception 'Solicitacao indisponivel.'; end if;
end $$;
create or replace function public.decide_professor(p_user uuid,p_approve boolean)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_leader() then raise exception 'Apenas o lider pode aprovar.'; end if;
  update public.profiles set role=case when p_approve then 'professor' else 'aluno' end,
    request_status=case when p_approve then 'aprovada' else 'recusada' end
    where id=p_user and role='aluno' and request_status='pendente';
  if not found then raise exception 'Pedido nao encontrado.'; end if;
end $$;
create or replace function public.revoke_professor(p_user uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_leader() then raise exception 'Apenas o lider pode revogar.'; end if;
  update public.profiles set role='aluno',request_status='nenhuma'
    where id=p_user and role='professor';
  if not found then raise exception 'Professor nao encontrado.'; end if;
end $$;
create or replace function public.book_ride(p_ride uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare v_ride public.rides%rowtype; v_bookings integer;
begin
  if auth.uid() is null then raise exception 'Entre na sua conta.'; end if;
  select * into v_ride from public.rides where id=p_ride for update;
  if not found then raise exception 'Carona nao encontrada.'; end if;
  if v_ride.author_id=auth.uid() then raise exception 'Nao pode reservar a propria carona.'; end if;
  if exists(select 1 from public.ride_bookings where ride_id=p_ride and user_id=auth.uid()) then
    raise exception 'Voce ja reservou esta carona.'; end if;
  select count(*) into v_bookings from public.ride_bookings where ride_id=p_ride;
  if v_bookings >= v_ride.seats then raise exception 'Carona lotada.'; end if;
  insert into public.ride_bookings(ride_id,user_id) values(p_ride,auth.uid());
end $$;
create or replace function public.cancel_ride(p_ride uuid) returns void
language plpgsql security definer set search_path = '' as $$
begin
  delete from public.ride_bookings where ride_id=p_ride and user_id=auth.uid();
  if not found then raise exception 'Reserva nao encontrada.'; end if;
end $$;
create or replace function public.claim_found_item(p_item uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare v_author uuid;
begin
  select author_id into v_author from public.found_items where id=p_item and retrieved_at is null;
  if not found then raise exception 'Item nao disponivel.'; end if;
  if v_author=auth.uid() then raise exception 'Voce cadastrou este item.'; end if;
  insert into public.found_item_claims(item_id,claimant_id) values(p_item,auth.uid())
    on conflict (item_id,claimant_id) do update set status='pendente', created_at=now()
    where public.found_item_claims.status='recusada';
end $$;
create or replace function public.review_found_claim(p_item uuid,p_claimant uuid,p_approve boolean)
returns void language plpgsql security definer set search_path = '' as $$
declare v_author uuid;
begin
  select author_id into v_author from public.found_items where id=p_item and retrieved_at is null for update;
  if not found then raise exception 'Item ja retirado.'; end if;
  if v_author<>auth.uid() and not public.is_leader() then raise exception 'Sem permissao.'; end if;
  update public.found_item_claims set status=case when p_approve then 'aprovada' else 'recusada' end
   where item_id=p_item and claimant_id=p_claimant and status='pendente';
  if not found then raise exception 'Solicitacao nao encontrada.'; end if;
end $$;
create or replace function public.confirm_found_pickup(p_item uuid) returns void
language plpgsql security definer set search_path = '' as $$
begin
  update public.found_items set retrieved_at=now(),retrieved_by_id=auth.uid()
  where id=p_item and retrieved_at is null and exists(
    select 1 from public.found_item_claims c where c.item_id=p_item
       and c.claimant_id=auth.uid() and c.status='aprovada');
  if not found then raise exception 'Sua retirada ainda nao foi aprovada.'; end if;
end $$;

-- Nao permitir execucao anonima de RPCs; checagem de auth.uid dentro de funcoes.
revoke all on function public.is_leader(),public.is_professor(),public.request_professor(),
  public.decide_professor(uuid,boolean),public.revoke_professor(uuid),
  public.book_ride(uuid),public.cancel_ride(uuid),public.claim_found_item(uuid),
  public.review_found_claim(uuid,uuid,boolean),public.confirm_found_pickup(uuid) from public,anon;
grant execute on function public.is_leader(),public.is_professor(),public.request_professor(),
  public.decide_professor(uuid,boolean),public.revoke_professor(uuid),
  public.book_ride(uuid),public.cancel_ride(uuid),public.claim_found_item(uuid),
  public.review_found_claim(uuid,uuid,boolean),public.confirm_found_pickup(uuid) to authenticated;

-- Apenas acoes explicitamente permitidas sao acessiveis via API REST.
revoke all on public.courses,public.rooms,public.profiles,public.reservations,
 public.notices,public.found_items,public.found_item_claims,public.rides,
 public.ride_bookings,public.events from anon,authenticated;
grant select on public.courses to anon;
grant select,insert,update,delete on public.courses,public.rooms to authenticated;
grant select on public.profiles to authenticated;
grant update(course) on public.profiles to authenticated;
grant select,insert,delete on public.reservations,public.notices,public.found_items,
 public.rides,public.events to authenticated;
grant select on public.found_item_claims,public.ride_bookings to authenticated;

-- Fotos privadas: o nome do objeto deve comecar com id-do-usuario/.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
 values('found-items','found-items',false,1048576,array['image/jpeg'])
 on conflict(id) do nothing;
create policy item_photo_read on storage.objects for select to authenticated
 using(bucket_id='found-items');
create policy item_photo_write on storage.objects for insert to authenticated
 with check(bucket_id='found-items' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy item_photo_delete on storage.objects for delete to authenticated
 using(bucket_id='found-items' and
  ((storage.foldername(name))[1] = (select auth.uid())::text or public.is_leader()));

-- Real-time: se uma tabela ja fizer parte da publicacao, nao adiciona de novo.
do $$ declare t text; begin
  foreach t in array array['profiles','courses','rooms','reservations','notices',
   'found_items','found_item_claims','rides','ride_bookings','events'] loop
   if not exists (select 1 from pg_publication_tables
     where pubname='supabase_realtime' and schemaname='public' and tablename=t) then
     execute format('alter publication supabase_realtime add table public.%I',t);
   end if;
  end loop;
end $$;
