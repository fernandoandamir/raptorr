-- ============================================================
-- RAPTOR — Full Database Schema
-- Run this in your Supabase SQL Editor (Project > SQL Editor)
-- ============================================================

-- ── Extensions ───────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ── USERS (extends auth.users) ───────────────────────────────
CREATE TABLE IF NOT EXISTS public.users (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username    TEXT NOT NULL UNIQUE,
  avatar_url  TEXT,
  status      TEXT NOT NULL DEFAULT 'online'  -- online | idle | dnd | invisible
               CHECK (status IN ('online','idle','dnd','invisible')),
  bio         TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── SERVERS ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.servers (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name        TEXT NOT NULL,
  icon_url    TEXT,
  owner_id    UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  invite_code TEXT UNIQUE DEFAULT substr(md5(random()::text), 1, 8),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── SERVER MEMBERS ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.server_members (
  server_id   UUID NOT NULL REFERENCES public.servers(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES public.users(id)   ON DELETE CASCADE,
  role        TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('owner','admin','member')),
  joined_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (server_id, user_id)
);

-- ── CHANNELS ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.channels (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  server_id   UUID NOT NULL REFERENCES public.servers(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  type        TEXT NOT NULL DEFAULT 'text' CHECK (type IN ('text','voice')),
  topic       TEXT,
  position    INT  NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── MESSAGES ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.messages (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  channel_id  UUID REFERENCES public.channels(id) ON DELETE CASCADE,
  dm_id       UUID,                          -- used for DMs (both user ids sorted)
  author_id   UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  content     TEXT NOT NULL,
  edited_at   TIMESTAMPTZ,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── REACTIONS ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.reactions (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  message_id  UUID NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES public.users(id)    ON DELETE CASCADE,
  emoji       TEXT NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (message_id, user_id, emoji)
);

-- ── TYPING INDICATORS (ephemeral — cleared after 5s by app) ──
CREATE TABLE IF NOT EXISTS public.typing (
  channel_id  UUID NOT NULL,
  user_id     UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (channel_id, user_id)
);

-- ── DM THREADS ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.dm_threads (
  id           TEXT PRIMARY KEY,   -- sorted concat of two user UUIDs
  user_a       UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  user_b       UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── INDEXES ───────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_messages_channel   ON public.messages(channel_id, created_at);
CREATE INDEX IF NOT EXISTS idx_messages_dm        ON public.messages(dm_id, created_at);
CREATE INDEX IF NOT EXISTS idx_reactions_message  ON public.reactions(message_id);
CREATE INDEX IF NOT EXISTS idx_server_members     ON public.server_members(server_id);
CREATE INDEX IF NOT EXISTS idx_channels_server    ON public.channels(server_id, position);

-- ── ROW-LEVEL SECURITY ────────────────────────────────────────
ALTER TABLE public.users          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.servers        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.server_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.channels       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reactions      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.typing         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dm_threads     ENABLE ROW LEVEL SECURITY;

-- Users: anyone can read; only owner can update
CREATE POLICY "users_select"  ON public.users FOR SELECT USING (true);
CREATE POLICY "users_insert"  ON public.users FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "users_update"  ON public.users FOR UPDATE USING (auth.uid() = id);

-- Servers: members can read; authenticated users can create
CREATE POLICY "servers_select" ON public.servers FOR SELECT
  USING (
    id IN (SELECT server_id FROM public.server_members WHERE user_id = auth.uid())
    OR owner_id = auth.uid()
  );
CREATE POLICY "servers_insert" ON public.servers FOR INSERT WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "servers_update" ON public.servers FOR UPDATE USING (auth.uid() = owner_id);
CREATE POLICY "servers_delete" ON public.servers FOR DELETE USING (auth.uid() = owner_id);

-- Server members: members can read their servers; anyone can join via invite
CREATE POLICY "sm_select" ON public.server_members FOR SELECT USING (true);
CREATE POLICY "sm_insert" ON public.server_members FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "sm_delete" ON public.server_members FOR DELETE USING (auth.uid() = user_id);

-- Channels: server members only
CREATE POLICY "channels_select" ON public.channels FOR SELECT
  USING (server_id IN (SELECT server_id FROM public.server_members WHERE user_id = auth.uid()));
CREATE POLICY "channels_insert" ON public.channels FOR INSERT
  WITH CHECK (server_id IN (SELECT server_id FROM public.server_members WHERE user_id = auth.uid()));
CREATE POLICY "channels_update" ON public.channels FOR UPDATE
  USING (server_id IN (
    SELECT server_id FROM public.server_members WHERE user_id = auth.uid() AND role IN ('owner','admin')
  ));
CREATE POLICY "channels_delete" ON public.channels FOR DELETE
  USING (server_id IN (
    SELECT server_id FROM public.server_members WHERE user_id = auth.uid() AND role IN ('owner','admin')
  ));

-- Messages: channel members can read/write; authors can delete
CREATE POLICY "messages_select" ON public.messages FOR SELECT USING (true);
CREATE POLICY "messages_insert" ON public.messages FOR INSERT WITH CHECK (auth.uid() = author_id);
CREATE POLICY "messages_update" ON public.messages FOR UPDATE USING (auth.uid() = author_id);
CREATE POLICY "messages_delete" ON public.messages FOR DELETE USING (auth.uid() = author_id);

-- Reactions
CREATE POLICY "reactions_select" ON public.reactions FOR SELECT USING (true);
CREATE POLICY "reactions_insert" ON public.reactions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "reactions_delete" ON public.reactions FOR DELETE USING (auth.uid() = user_id);

-- Typing
CREATE POLICY "typing_all" ON public.typing FOR ALL USING (true) WITH CHECK (auth.uid() = user_id);

-- DM threads
CREATE POLICY "dm_select" ON public.dm_threads FOR SELECT
  USING (auth.uid() = user_a OR auth.uid() = user_b);
CREATE POLICY "dm_insert" ON public.dm_threads FOR INSERT
  WITH CHECK (auth.uid() = user_a OR auth.uid() = user_b);

-- ── REALTIME ──────────────────────────────────────────────────
-- Enable realtime on key tables (run in Supabase Dashboard > Database > Replication)
-- Or run:
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.reactions;
ALTER PUBLICATION supabase_realtime ADD TABLE public.typing;
ALTER PUBLICATION supabase_realtime ADD TABLE public.users;

-- ── TRIGGER: auto-create user profile on signup ───────────────
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.users (id, username, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    NEW.raw_user_meta_data->>'avatar_url'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
