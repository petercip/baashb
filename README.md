# baashb

A self-hosted, multi-tenant community club platform. One Rails app serves multiple invitation-only clubs — each with its own domain, branding, members, events, and Stripe account. BAASH-B (Bay Area All-Star Has-Beens) is the reference club.

**v0.1.0.0** — Rails 8.1 · Ruby 4.0.1 · PostgreSQL · Kamal

---

## What it does

- **Club operator** signs up, sets a custom domain, uploads branding (logo, accent color, font), and adds Stripe keys.
- **Members** are invited via magic link. They sign in with email/password or Google OAuth.
- **Organizers** create events (draft → published → cancelled), set capacity and ticket price, and send announcements.
- **Members** RSVP — free events via atomic capacity check; paid events via Stripe Checkout. Confirmed attendees get an iCal file.
- **Receipts** — 501(c)3 donation receipts issued for voluntary donation line items (separate from ticket price).

Each club is isolated: members, events, RSVPs, and Stripe keys are all scoped to a club. A member of Club A cannot access Club B data.

---

## Stack

| Layer | Technology |
|-------|------------|
| Framework | Rails 8.1.3 |
| Language | Ruby 4.0.1 (RVM) |
| Database | PostgreSQL |
| Background jobs | Solid Queue (runs in Puma in v1) |
| Caching | Solid Cache |
| WebSockets | Solid Cable |
| Frontend | Hotwire (Turbo + Stimulus) |
| Asset pipeline | Propshaft |
| Payments | Stripe Checkout (per-club keys, encrypted) |
| Deployment | Kamal |
| Edge proxy | kamal-proxy (TLS via Let's Encrypt) |
| Rate limiting | rack-attack |
| Auth | email/password (bcrypt) + Google OAuth + magic-link invites |

---

## Local setup

**Prerequisites:** Ruby 4.0.1 via RVM, PostgreSQL, Node.js (for CSS watcher).

```bash
git clone https://github.com/petercip/baashb
cd baashb

# Install dependencies
bundle install

# Create and seed the database
bin/rails db:create db:migrate db:seed

# Start the dev server
bin/dev
```

The server runs on `localhost:3000`. For multi-tenant testing, use `lvh.me` subdomains (they resolve to 127.0.0.1):

| URL | Club |
|-----|------|
| `http://baashb.lvh.me:3000` | BAASH-B (the reference club) |
| `http://other.lvh.me:3000` | Any other seeded club |

All `*.lvh.me` subdomains are allowed in development. `ClubMiddleware` maps the subdomain to a `Club` record automatically.

---

## Testing

```bash
bundle exec rspec                 # full suite (164 examples)
bundle exec rspec spec/models     # models
bundle exec rspec spec/requests   # request specs (controllers + routes)
bundle exec rspec spec/system     # system/E2E tests (Capybara + Playwright)
bundle exec rspec spec/mailers    # mailers
bundle exec rspec spec/jobs       # background jobs
bundle exec rspec spec/middleware # ClubMiddleware
```

Critical paths that must pass before any deploy:
1. Stripe webhook idempotency — same `checkout_session_id` delivered twice creates zero duplicate RSVPs
2. Oversell race — two members claim last spot simultaneously; one confirms, one is refunded
3. Cross-club isolation — a member of Club A cannot access Club B data

---

## Multi-tenancy

**How it works:** `ClubMiddleware` (a Rack middleware inserted before the session) sets `Current.club` from the `Host` header on every request:

1. Check `Club.find_by(custom_domain: host)` — clubs with a custom domain (e.g. `baash-b.org`)
2. Fall back to `Club.find_by(slug: subdomain)` — slug-based subdomains (e.g. `baashb.yourdomain.com`)
3. Neither matches → 404

**Rules for contributors:**
- Always scope queries via `current_club`: `current_club.events.published.order(:starts_at)` — never `Event.all`
- Background jobs receive `club_id` as an argument and do `Club.find(club_id)` directly — never `Current.club`
- All models that belong to a club include `ClubScoped` concern (`belongs_to :club` + presence validation)
- Never use `default_scope` for club scoping

---

## Architecture notes

- **RSVP = payment** for paid events. Creating a Stripe Checkout session creates an `Rsvp` with `status: :pending_payment` (capacity hold). The webhook transitions it to `:confirmed`.
- **Session security** — `resume_session` checks `member.active?` and `member.club_id == Current.club.id` on every request. Removed members are immediately locked out. Password resets revoke all existing sessions.
- **Slug routing** — all resource URLs use human-readable slugs (`/events/spring-dinner-2026`), never numeric IDs. Implemented with `friendly_id` scoped to club.
- **Stripe keys** — stored encrypted on the `Club` model via Active Record Encryption. Never logged or stored in plain text.

---

## Deployment

baashb deploys with [Kamal](https://kamal-deploy.org). kamal-proxy handles TLS
via Let's Encrypt.

```bash
bin/kamal setup    # first deploy — installs Docker, starts proxy, deploys app
bin/kamal deploy   # subsequent deploys
```

**First deploy only** — after `bin/kamal setup`, load the Solid Queue, Cache,
and Cable schemas (these don't run via the normal db:prepare path):

```bash
bin/kamal app exec "bin/rails db:schema:load:queue db:schema:load:cache db:schema:load:cable"
```

**Secrets required in `.kamal/secrets`:**
- `RAILS_MASTER_KEY` — from `config/master.key`
- `POSTGRES_PASSWORD` + `BAASHB_DATABASE_PASSWORD=$POSTGRES_PASSWORD`
- `KAMAL_REGISTRY_PASSWORD` — GitHub PAT with `write:packages` scope
- `HETZNER_STORAGE_ACCESS_KEY_ID` / `HETZNER_STORAGE_SECRET_ACCESS_KEY` / `HETZNER_STORAGE_BUCKET` / `HETZNER_STORAGE_ENDPOINT`

See [`infra/README.md`](infra/README.md) for the full provisioning guide.

---

## Design system

See [`DESIGN.md`](DESIGN.md) for the full design system: typography (Inter), color tokens (gold `#c8a96e` accent, warm `#fafaf8` background), spacing scale, component specs, motion, and accessibility guidelines.

---

## Documentation

| File | What it covers |
|------|---------------|
| [`CLAUDE.md`](CLAUDE.md) | AI agent conventions, code style, testing rules |
| [`DESIGN.md`](DESIGN.md) | Typography, color, spacing, components, motion, a11y |
| [`CHANGELOG.md`](CHANGELOG.md) | Version history |
| [`TODOS.md`](TODOS.md) | Known gaps and future work |

---

## License

Private. Not open source.
