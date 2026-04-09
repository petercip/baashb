# CLAUDE.md — baashb

Project conventions for AI agents (Claude Code, /review, /ship, /qa, etc.).

## Project

**baashb** — Generic multi-tenant community club platform. Self-hosted Rails 8.1 app. One install serves multiple clubs (e.g. BAASH-B, the reference club). Each club has its own domain, branding, members, events, and Stripe account.

**Design doc:** `~/.gstack/projects/baashb/pete-master-design-20260324-222402.md`
**Design system:** `DESIGN.md` — typography (Inter), color tokens, spacing scale, component specs, motion, a11y
**CEO plan:** `~/.gstack/projects/baashb/ceo-plans/2026-03-24-community-club-platform.md`

## Stack

- **Ruby 4.0.1** (RVM) + **Rails 8.1.3**
- **PostgreSQL** — 1 DB (`baashb_production`). Solid Cache, Queue, and Cable all share the primary database via named connections in `database.yml`. TODO: split to separate DBs as traffic grows.
- **Solid Queue** — background jobs, runs in Puma (SOLID_QUEUE_IN_PUMA=true). Schema: `db/queue_schema.rb`
- **Solid Cache** — fragment/session caching. Schema: `db/cache_schema.rb`
- **Solid Cable** — Action Cable adapter. Schema: `db/cable_schema.rb`
- **Note:** Solid schemas are separate from `db/schema.rb` (Rails multi-database named connections). On first deploy, run: `bin/kamal app exec "bin/rails db:schema:load:queue db:schema:load:cache db:schema:load:cable"`
- **Kamal** — deployment (kamal-proxy for TLS via Let's Encrypt)
- **Propshaft** — asset pipeline
- **Hotwire** (Turbo + Stimulus) — frontend interactivity
- **Stripe** — payments (per-club keys, encrypted with AR Encryption)
- **Active Record Encryption** — encrypts Club Stripe keys (`rails db:encryption:init`)

## Running Locally

```bash
bin/dev          # starts Rails + CSS watcher
bin/rails server # Rails only
```

Server runs on `localhost:3000`. Use `lvh.me` subdomains for multi-tenant testing:
- `baashb.lvh.me:3000` → BAASH-B club (slug: baashb)
- `other.lvh.me:3000` → any other seeded club

## Testing

**Framework:** RSpec + FactoryBot + Shoulda Matchers + Capybara + capybara-playwright-driver

```bash
bundle exec rspec                          # full suite
bundle exec rspec spec/models              # models only
bundle exec rspec spec/system              # system/E2E tests (Playwright)
bundle exec rspec spec/requests            # request specs (controllers + routes)
bundle exec rspec spec/jobs                # background job specs
bundle exec rspec spec/middleware          # ClubMiddleware specs
```

**Test file conventions:**
- Models → `spec/models/`
- Requests → `spec/requests/`
- System (E2E) → `spec/system/`
- Jobs → `spec/jobs/`
- Mailers → `spec/mailers/`
- Middleware → `spec/middleware/`
- Factories → `spec/factories/`
- Support → `spec/support/`

**Coverage target:** 100% of new codepaths. No exceptions.

**Critical tests (must pass before any deploy):**
1. Stripe webhook idempotency: same `checkout_session_id` delivered twice → zero duplicate RSVPs
2. Oversell race: two members simultaneously claim last spot → one confirmed, one refunded
3. Cross-club isolation: Club A member cannot access Club B data

## Multi-Tenancy Rules

**RULE 1 — No `default_scope` for club scoping.** Use explicit association scoping instead:
```ruby
# ✅ Always do this in controllers:
@events = current_club.events.published.order(:starts_at)

# ❌ Never do this:
@events = Event.all   # wrong — not scoped to club
```

**RULE 2 — `ClubScoped` concern** adds `belongs_to :club` + `validates :club, presence: true`. No `default_scope`.

**RULE 3 — Background jobs** receive `club_id` as an argument and look up `Club.find(club_id)` directly. Never rely on `Current.club` in a job.

**RULE 4 — `ClubMiddleware`** (Rack middleware, inserted before `ActionDispatch::Session`) sets `Current.club` from the Host header:
1. Check `Club.find_by(custom_domain: host)` first
2. Fall back to `Club.find_by(slug: subdomain)`
3. If neither matches, render 404

**RULE 5 — Stripe keys** are per-club, stored encrypted on the `Club` model:
```ruby
encrypts :stripe_secret_key, :stripe_publishable_key, :stripe_webhook_secret
```
Use `current_club.stripe_secret_key` in all Stripe calls. Never use a global `Stripe.api_key`.

## URL Conventions (Pretty URLs)

All resource URLs use human-readable slugs via the `friendly_id` gem. **No numeric IDs in URLs.**

```ruby
# Models use :slugged + :scoped (scoped to club for multi-tenant uniqueness)
friendly_id :name, use: [:slugged, :scoped], scope: :club
```

**Finding records — always scope to club AND use friendly finder:**
```ruby
# ✅ Correct
@event = current_club.events.friendly.find(params[:slug])

# ❌ Wrong — not scoped to club, exposes cross-club data
@event = Event.friendly.find(params[:slug])
```

**Routes — use `param: :slug`:**
```ruby
resources :events, param: :slug
# Generates: /events/:slug (not /events/:id)
```

**Slug columns:** `Event`, `Member`, `Announcement` each have a `slug` string column (indexed, unique within club). Migration also creates `friendly_id_slugs` table for Member slug history (enables 301 redirects when member name changes).

**Slug stability:** Event and Announcement slugs are frozen after creation — never regenerated on title edits (avoids breaking URLs in confirmation emails and iCal entries). Member slugs regenerate on name change; history table issues 301s from old slugs.

## Key Architectural Decisions

- **RSVP = payment** — paying via Stripe Checkout IS the RSVP. Free events bypass Stripe entirely.
- **Pending RSVP at Checkout creation** — create `Rsvp` with `status: :pending_payment` when Checkout session is created (capacity check + hold). Webhook transitions to `:confirmed`.
- **Cancel button gated on `paid_at IS NOT NULL`** — prevents race between cancel and incoming webhook.
- **Donation ≠ ticket price** — voluntary donation is a separate Stripe line item. Event tickets are NOT charitable. Receipts issued for donations only.
- **No waitlist** — events close at capacity. No spot-hold mechanism.
- **Per-club identity** — `Member belongs_to :club`. No cross-club SSO.

## Code Style

- Thin controllers — complex flows go in service objects (`app/services/`)
- Two service objects with dedicated test coverage: `Rsvp::CheckoutService`, `Rsvp::CancelService`
- Stripe webhook event types each get their own handler class: `StripeWebhooks::CheckoutCompleted`, `StripeWebhooks::CheckoutExpired`
- ASCII diagrams in model comments for state machines (Member.status, Rsvp.status, Club.ssl_status)
- `price_cents == 0` for free event check — no `is_free` boolean column

## Security Notes

- `StripeWebhooksController` skips CSRF + auth, verifies Stripe signature on every request
- CSV export output must escape formula injection (`=`, `+`, `-`, `@` prefixes)
- `rack-attack` gem for rate limiting on auth + invite endpoints (sign-in: 5/20s, password reset: 3/hr, magic link: 10/min)
- All Stripe keys in encrypted columns; never logged
- `Club.font_choice` validated against `ALLOWED_FONTS` allowlist (array literal, not `%w[]`) to prevent CSS injection
- `resume_session` checks `member.active?` AND `member.club_id == Current.club&.id` — removed members locked out immediately; cross-club session replay blocked

## Prompt / LLM Changes

No LLM integration in this project.

## Skill routing

When the user's request matches an available skill, ALWAYS invoke it using the Skill
tool as your FIRST action. Do NOT answer directly, do NOT use other tools first.
The skill has specialized workflows that produce better results than ad-hoc answers.

Key routing rules:
- Product ideas, "is this worth building", brainstorming → invoke office-hours
- Bugs, errors, "why is this broken", 500 errors → invoke investigate
- Ship, deploy, push, create PR → invoke ship
- QA, test the site, find bugs → invoke qa
- Code review, check my diff → invoke review
- Update docs after shipping → invoke document-release
- Weekly retro → invoke retro
- Design system, brand → invoke design-consultation
- Visual audit, design polish → invoke design-review
- Architecture review → invoke plan-eng-review
- Save progress, checkpoint, resume → invoke checkpoint
- Code quality, health check → invoke health
