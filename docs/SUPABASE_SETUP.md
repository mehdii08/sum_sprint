# Sum Sprint – Supabase Setup Guide

This guide walks through setting up Supabase as the backend for Sum Sprint v2 online competitions.

## Prerequisites

1. A [Supabase](https://supabase.com) account (free tier works).
2. A Supabase project created (get URL and anon key from Settings → API).

## Step 1: Configure the App

Open `lib/config/supabase_config.dart` and replace the placeholder values:

```dart
class SupabaseConfig {
  static const String url = 'https://YOUR-PROJECT-ID.supabase.co';
  static const String anonKey = 'eyJh...your-anon-key...';
}
```

> **Security note:** In production, never commit real keys. Use environment variables or a `.env` file with `flutter_dotenv`. The current placeholder approach is for development only.

## Step 2: Run the Database Migration

1. Go to your Supabase project dashboard → **SQL Editor**.
2. Click **New query**.
3. Copy the entire contents of `supabase/migrations/001_initial_schema.sql`.
4. Paste into the SQL editor and click **Run**.

### What the migration creates:

| Component | Description |
|-----------|-------------|
| `profiles` | User profiles extending `auth.users` (nickname, points) |
| `competitions` | Competition metadata (name, dates, challenges JSON, prize pool) |
| `participants` | Users who joined each competition (score tracking) |
| `challenge_results` | Individual challenge outcomes (for history) |
| RLS policies | Row-level security for all tables |
| RPC functions | `join_competition` and `update_participant_score` |
| Trigger | Auto-creates profile on signup |

### Tables Diagram

```
auth.users (Supabase built-in)
    │
    └── profiles (1:1)
           │
           ├── participants (M:M with competitions)
           │      │
           │      └── competitions
           │
           └── challenge_results
                  │
                  └── competitions
```

## Step 3: Auth Configuration — **IMPORTANT**

### Disable Email Confirmation (Required for Dev)

Email confirmation links don't work on mobile/emulator without deep link setup. **Disable it now:**

1. Go to **Authentication** → **Settings** in the Supabase dashboard.
2. Scroll to **Email Auth** section.
3. **Turn OFF** "Enable email confirmations" (or "Confirm email").
4. Click **Save**.

This lets users sign up and log in immediately — no email verification needed. The database trigger still creates their profile with the nickname and 500 starting points.

### Why This Is Needed

Supabase sends confirmation emails with a link like `http://localhost:52023/...`. On a phone/emulator, clicking that link opens the browser, not the app — and the link doesn't work because no server is listening on that port. Without deep linking configured (an advanced platform-specific setup), email confirmation links are dead ends.

### Social Login (Optional — Future)

To add Google, Apple, or other OAuth providers later:
1. Go to **Authentication** → **Sign In / Up**.
2. Enable the desired provider and follow its configuration steps.

### Enabling Email Confirmation Later (Production)

If you ever want email confirmation in production:
1. Set up **deep linking** for Android and iOS (see Supabase Flutter docs)
2. In Supabase dashboard → **Authentication** → **URL Configuration**, set the **Site URL** to your app's deep link scheme (e.g. `sumsprint://login-callback`)
3. Add `authFlowType: AuthFlowType.pkce` and a redirect URL to the `Supabase.initialize()` call in `main.dart`
4. Turn email confirmations back **ON**

## Step 4: Create Seed Competitions (Optional)

To create test competitions, uncomment and modify the seed data at the bottom of `001_initial_schema.sql`, or run this in the SQL editor:

```sql
insert into public.competitions (name, description, start_date, end_date, challenges, entry_points, prize_pool, status)
values (
  'Weekend Math Sprint',
  'Compete in 3 addition challenges! Top 3 win points.',
  now(),
  now() + interval '7 days',
  '[
    {"id":"easy_add","name":"Easy Addition","description":"Numbers 1-10, 5s","operation":"+","minNumber":1,"maxNumber":10,"timePerQuestionSeconds":5,"questionCount":10},
    {"id":"medium_add","name":"Medium Addition","description":"Numbers 5-20, 4s","operation":"+","minNumber":5,"maxNumber":20,"timePerQuestionSeconds":4,"questionCount":10},
    {"id":"hard_mix","name":"Hard Mix","description":"Numbers 10-50, 3s","operation":"+","minNumber":10,"maxNumber":50,"timePerQuestionSeconds":3,"questionCount":10}
  ]'::jsonb,
  100,
  1000,
  'active'
);
```

## Step 5: Build & Run

```bash
flutter pub get
flutter run
```

The app will connect to Supabase on launch. The offline warm-up mode works without any server connection — only the Competitions section requires Supabase.

## How It Works

### Auth Flow
1. User taps "Competitions" → routed to LoginScreen
2. User enters email/password (or creates account)
3. `AuthProvider.signUp()` or `signIn()` calls Supabase Auth
4. On successful signup, a `profiles` row is created with 500 starting points
5. On login, the profile is fetched and nickname is synced

### Competition Flow
1. `CompetitionsScreen` fetches all competitions from `public.competitions`
2. User taps a competition → `CompetitionDetailScreen`
3. User joins by tapping "Join" → calls `join_competition` RPC (deducts points, inserts participant)
4. User plays challenges → `GameScreen` (same as offline mode)
5. On completion → `ResultScreen` submits result to Supabase via `CompetitionProvider.submitChallengeResult()`
6. This calls `update_participant_score` RPC (accumulates score)
7. Leaderboard is fetched from `public.participants` joined with `public.profiles`

### Offline Mode (Unchanged)
- Warm Up mode uses `LocalResultRepository` (SharedPreferences)
- No Supabase connection required
- Works completely offline
- The two modes are independent — they don't interfere with each other

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Failed to load competitions" | Check your Supabase URL and anon key in `supabase_config.dart` |
| "Insufficient points" | Users start with 500 points. Adjust the default in the profiles table or seed data |
| RLS policy errors | Run the full migration SQL — make sure all `create policy` statements executed |
| RPC function not found | The `join_competition` and `update_participant_score` functions must be created in the SQL editor |
| Auth email not sending | Check Supabase → Authentication → Settings → email configuration |

## Environment Variables (Production)

For production, avoid hardcoding credentials. Create a `.env` file:

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

Add `flutter_dotenv` to pubspec.yaml, then load from env:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

await dotenv.load();
await Supabase.initialize(
  url: dotenv.env['SUPABASE_URL']!,
  anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
);
```

> The current `SupabaseConfig` constants file is for development simplicity.
> Switch to dotenv before deploying to production.
