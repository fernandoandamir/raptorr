# ⚡ RAPTOR

A production-ready, real-time chat application built with React + Supabase. Discord-inspired UI with a dark tactical aesthetic.

---

## Features

| Feature | Status |
|---|---|
| Sign up / Log in / Log out | ✅ |
| User profiles + status (online / idle / DND / invisible) | ✅ |
| Create & join servers via invite code | ✅ |
| Text channels with real-time messaging | ✅ |
| Voice channel UI (join/leave/mute/deafen) | ✅ |
| Direct messages (1-on-1) | ✅ |
| Message edit & delete | ✅ |
| Emoji reactions | ✅ |
| Typing indicators (real-time) | ✅ |
| Online presence indicators | ✅ |
| Member list per channel | ✅ |
| Server settings + invite code sharing | ✅ |
| Dark mode (always on — it's Raptor) | ✅ |

---

## Stack

- **Frontend**: React 18 + Vite + Tailwind CSS
- **Backend**: Supabase (PostgreSQL + Auth + Realtime)
- **Fonts**: Bebas Neue (display) · DM Sans (body) · JetBrains Mono

---

## Quick Start

### 1. Set up the database

Open your [Supabase SQL Editor](https://app.supabase.com) and run the entire contents of **`SCHEMA.sql`**. This creates all tables, RLS policies, indexes, and the new-user trigger.

### 2. Enable Realtime

In Supabase Dashboard → **Database → Replication**, ensure these tables are in the `supabase_realtime` publication:
- `messages`
- `reactions`
- `typing`
- `users`

_(The SCHEMA.sql `ALTER PUBLICATION` statements do this automatically if your DB user has permission.)_

### 3. Install & run locally

```bash
cd raptor
npm install
npm run dev
```

Open [http://localhost:5173](http://localhost:5173)

### 4. Build for production

```bash
npm run build
npm run preview   # preview the build locally
```

---

## Project Structure

```
raptor/
├── SCHEMA.sql                        # Full Supabase DB schema — run this first!
├── index.html
├── src/
│   ├── main.jsx                      # Entry point
│   ├── App.jsx                       # Router + auth guard
│   ├── index.css                     # Global styles + Tailwind
│   ├── lib/
│   │   └── supabase.js               # Supabase client
│   ├── context/
│   │   └── AuthContext.jsx           # Auth + profile state
│   └── components/
│       ├── auth/
│       │   └── AuthPage.jsx          # Login + Sign up
│       ├── layout/
│       │   ├── AppLayout.jsx         # Main 3-column shell
│       │   ├── UserPanel.jsx         # Bottom user bar (status, mute)
│       │   └── WelcomeView.jsx       # Empty state
│       ├── server/
│       │   ├── ServerRail.jsx        # Far-left server icon column
│       │   ├── ServerSidebar.jsx     # Channel list + server menu
│       │   ├── CreateServerModal.jsx # Create a new server
│       │   ├── JoinServerModal.jsx   # Join via invite code
│       │   ├── CreateChannelModal.jsx
│       │   └── ServerSettingsModal.jsx
│       ├── channel/
│       │   └── ChannelView.jsx       # Text channel chat panel
│       ├── message/
│       │   ├── MessageList.jsx       # Scrollable message list
│       │   ├── MessageRow.jsx        # Single message + reactions + actions
│       │   ├── MessageInput.jsx      # Textarea + send + emoji
│       │   ├── EmojiPicker.jsx       # Quick emoji grid
│       │   └── TypingIndicator.jsx   # "Alice is typing…"
│       ├── dm/
│       │   ├── DMSidebar.jsx         # DM thread list + user search
│       │   └── DMView.jsx            # 1-on-1 chat panel
│       ├── voice/
│       │   └── VoiceChannelView.jsx  # Voice channel UI
│       └── ui/
│           ├── Avatar.jsx            # User avatar with initial fallback
│           ├── StatusDot.jsx         # Coloured presence dot
│           ├── Tooltip.jsx           # Hover tooltip
│           └── Modal.jsx             # Base modal wrapper
```

---

## Database Schema (summary)

| Table | Purpose |
|---|---|
| `users` | Public profiles linked to `auth.users` |
| `servers` | Server records with invite codes |
| `server_members` | Many-to-many servers ↔ users with roles |
| `channels` | Text & voice channels belonging to a server |
| `messages` | Chat messages for channels and DMs |
| `reactions` | Emoji reactions on messages |
| `typing` | Ephemeral typing indicator rows (cleared after ~3 s) |
| `dm_threads` | Direct message thread identifiers |

All tables have Row-Level Security enabled. Users can only read/write data they are authorised to access.

---

## Extending Raptor

### Add real WebRTC voice
Wire `VoiceChannelView.jsx`'s `handleJoin` / `handleLeave` to a WebRTC library like [simple-peer](https://github.com/feross/simple-peer). Use Supabase Realtime channels for signalling.

### File / image uploads
Use `supabase.storage` — create a bucket called `attachments`, upload in `MessageInput.jsx`, and store the public URL in the message content or a separate `attachments` column.

### Push notifications
Use the Supabase Edge Functions + Web Push API, or integrate with services like OneSignal.

### Roles & permissions
`server_members.role` already has `owner | admin | member`. Extend RLS policies and the UI to enforce channel-level permissions.
