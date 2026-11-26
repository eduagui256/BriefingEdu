-- Briefing de identidade visual · schema do Supabase
-- ANTES DE EXECUTAR: na função is_admin (logo abaixo), troque o texto entre aspas pelo e-mail do seu usuário admin.
-- Cole tudo no SQL Editor do Supabase e execute uma vez.

-- 0) Quem é admin: só o e-mail abaixo lê e gerencia os briefings (mesmo que alguém consiga criar uma conta).
create or replace function public.is_admin()
returns boolean
language sql stable set search_path = public as $$
  select coalesce((auth.jwt() ->> 'email') = 'COLOQUE_SEU_EMAIL_AQUI', false)
$$;

-- 1) Tabela. Ninguém de fora lê ou escreve nela diretamente (RLS ligado, sem política para anon).
create table if not exists public.briefings (
  id            uuid primary key default gen_random_uuid(),
  token         text unique not null default replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', ''),
  cliente       text not null,
  tipo          text not null default 'identidade-visual',
  status        text not null default 'pendente' check (status in ('pendente','em_andamento','concluido')),
  respostas     jsonb not null default '{}'::jsonb,  -- leitura para você (texto, termômetros, cores...)
  estado        jsonb not null default '{}'::jsonb,  -- estado interno do formulário, para retomar de onde parou
  criado_em     timestamptz not null default now(),
  atualizado_em timestamptz not null default now(),
  concluido_em  timestamptz
);

alter table public.briefings enable row level security;

drop policy if exists "admin total" on public.briefings;
create policy "admin total" on public.briefings
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

grant select, insert, update, delete on public.briefings to authenticated;

-- 2) Funções que o cliente usa, sempre com o token do link. Só enxergam a própria linha.
create or replace function public.get_briefing(p_token text)
returns jsonb
language sql security definer set search_path = public stable as $$
  select jsonb_build_object('tipo', tipo, 'status', status, 'estado', estado)
  from public.briefings where token = p_token
$$;

create or replace function public.save_briefing(p_token text, p_estado jsonb, p_respostas jsonb, p_status text)
returns boolean
language plpgsql security definer set search_path = public as $$
declare n int;
begin
  if p_status not in ('em_andamento','concluido') then raise exception 'status invalido'; end if;
  if pg_column_size(p_estado) > 300000 or pg_column_size(p_respostas) > 300000 then raise exception 'payload grande demais'; end if;
  update public.briefings
     set estado = p_estado,
         respostas = p_respostas,
         status = p_status,
         atualizado_em = now(),
         concluido_em = case when p_status = 'concluido' then now() else concluido_em end
   where token = p_token and status <> 'concluido';
  get diagnostics n = row_count;
  return n > 0;
end $$;

-- Usada só pelo "keep-alive" para o projeto gratuito não pausar.
create or replace function public.ping() returns text
language sql security definer set search_path = public stable as $$ select 'ok'::text $$;

revoke all on function public.get_briefing(text) from public;
revoke all on function public.save_briefing(text, jsonb, jsonb, text) from public;
revoke all on function public.ping() from public;
grant execute on function public.get_briefing(text) to anon, authenticated;
grant execute on function public.save_briefing(text, jsonb, jsonb, text) to anon, authenticated;
grant execute on function public.ping() to anon, authenticated;

-- 3) Áudios. Bucket privado: o cliente só consegue enviar (e só na pasta do próprio token); só você ouve.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('audios', 'audios', false, 26214400,
        array['audio/webm','audio/mp4','audio/ogg','audio/mpeg','audio/wav','audio/x-m4a'])
on conflict (id) do nothing;

create or replace function public.token_valid(p text)
returns boolean
language sql security definer set search_path = public stable as $$
  select exists (select 1 from public.briefings where token = p and status <> 'concluido')
$$;
revoke all on function public.token_valid(text) from public;
grant execute on function public.token_valid(text) to anon, authenticated;

drop policy if exists "cliente envia audio" on storage.objects;
create policy "cliente envia audio" on storage.objects
  for insert to anon
  with check (bucket_id = 'audios' and public.token_valid((storage.foldername(name))[1]));

drop policy if exists "admin ouve audio" on storage.objects;
create policy "admin ouve audio" on storage.objects
  for select to authenticated using (bucket_id = 'audios' and public.is_admin());

drop policy if exists "admin apaga audio" on storage.objects;
create policy "admin apaga audio" on storage.objects
  for delete to authenticated using (bucket_id = 'audios' and public.is_admin());
