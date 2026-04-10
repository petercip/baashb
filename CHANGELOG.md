# Changelog

All notable changes to baashb are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [0.2.0.2] - 2026-04-10

### Fixed

- **Session cookie security** — added `secure: true` flag (production-only) to the session cookie set in `Authentication#start_new_session_for`. `force_ssl` + HSTS mitigated the gap in practice, but the flag was absent at the application layer. Defense-in-depth closed.
- **501c3 receipt gate** — `Club#receipt_configured?` no longer requires `ca_registry_number`. Clubs with `legal_name` + `ein` but no California registry number are legally entitled to issue charitable contribution receipts; the code was silently blocking them. The CA Registry line in both email templates remains conditionally displayed.

## [0.2.0.1] - 2026-04-09

### Changed

- **Paid event confirmation email** — CA Registry number is now omitted from the charitable receipt block when the club has none configured (previously printed blank). Clubs without a California registration number still issue legally valid receipts.
- **Plain-text email variant** — paid event confirmation now ships as a proper multipart message (HTML + plain text), so email clients that prefer plain text render the full confirmation and receipt.
- **Docker build** — `.dockerignore` updated to exclude `.md` files in all subdirectories, not just the project root.

### Fixed

- 501c3 receipt wording approved by accountant — `ca_registry_number` conditionality and "no goods or services" language confirmed correct.

## [0.2.0.0] - 2026-04-09

### Added

- **Paid events with Stripe Checkout** — clubs can set a ticket price on events; members
  pay via Stripe Checkout with per-club API keys; capacity is held atomically at checkout
  creation (not just on webhook arrival) to prevent oversell races
- **Optional charitable donation** — members can add a voluntary donation as a separate
  Stripe line item; donation amount shown on pre-checkout form with live running total
  (Stimulus `donation-total` controller)
- **Stripe webhook handlers** — signature-verified, CSRF-exempt `StripeWebhooksController`
  routes to three idempotent handlers: `CheckoutCompleted` (confirms RSVP, queues email),
  `CheckoutExpired` (destroys pending RSVP), `ChargeRefunded` (marks `refund_succeeded`)
- **Organizer RSVP cancellation + refund** — organizer attendee list shows a "Cancel &
  refund" button for paid RSVPs; calls `Rsvp::CancelService` with `:organizer` path which
  bypasses the member refund cutoff and issues a full `Stripe::Refund`
- **501c3 donation receipt in confirmation email** — paid confirmation email includes a
  receipt block gated on `club.receipt_configured?` (requires `legal_name`, `ein`,
  `ca_registry_number`) and `donation_amount_cents > 0`
- **`Rsvp::CheckoutService`** — service object: locks event row, creates/reactivates
  pending RSVP, calls `Stripe::Checkout::Session.create` with `expand: ["payment_intent.latest_charge"]`
- **`Rsvp::CancelService`** — service object: `:member` path enforces `paid_at.present?`
  and refund cutoff; `:organizer` path bypasses cutoff; free events cancel directly
- **Partial index on `rsvps.stripe_charge_id`** — `WHERE NOT NULL` index for fast
  `ChargeRefunded` webhook lookups by charge ID

### Changed

- Event show page: free events show a POST-form RSVP button; paid events show a link to
  the pre-checkout donation form (`/events/:slug/rsvp`); sold-out events show a badge
  with no action
- Organizer event form: price field now accepts dollar values (converted to cents on save)
- `ApplicationMailer` gains a `club_mail` helper that sets `from:` from `smtp_from` and
  `reply_to:` from `contact_email`, used by both free and paid confirmation emails

### Fixed

- Oversell race: `reserved_count` now includes `pending_payment` RSVPs in capacity
  enforcement so concurrent checkouts cannot both pass the capacity check
- `CheckoutService` now rescues `RuntimeError` (in addition to `Stripe::StripeError`)
  preventing a 500 if a member double-submits the checkout form

## [0.1.0.1] - 2026-04-09

### Fixed

- Announcements empty state ("No announcements yet.") now has correct left margin, matching the list layout

## [0.1.0.0] - 2026-03-26

### Added

- **Multi-tenant platform foundation** — Rails 8.1, PostgreSQL, Solid Queue/Cache/Cable
  sharing the primary database (split to dedicated DBs later as a TODO)
- **Club model** — multi-tenant root; each club has its own domain, branding, members,
  and Stripe keys; all keys encrypted via Active Record Encryption
- **ClubMiddleware** — Rack middleware that sets `Current.club` from the Host header
  (custom domain first, then slug subdomain fallback); bypasses `/up` health check
  for Kamal/Traefik probes
- **Member authentication** — email/password, Google OAuth, and organizer magic-link
  invite paths; sessions tracked in DB with explicit `expires_at`
- **Session security** — `resume_session` checks `member.active?` on every request,
  immediately locking out removed members; sessions fully revoked on password reset
- **Magic link security** — TOCTOU race eliminated with `MagicLink.lock.find_by`
  inside a transaction; cross-club guard and inactive-member guard added
- **Events** — full CRUD with draft/published/cancelled state machine; `publish`
  action distinct from `cancel`; `starts_at` required only on publish (drafts allowed
  without a date); friendly-id slugs scoped to club
- **RSVP flow** — free events: atomic capacity check with row-level lock; re-RSVP
  after cancellation reactivates the existing record (avoids DB unique-index error);
  paid event skeleton (Stripe integration TODO)
- **Organizer dashboard** — event management (create/edit/duplicate/publish/cancel),
  member management (invite/edit/remove), announcement drafting and sending,
  club settings (branding, SMTP, Stripe keys, 501c3 receipt fields)
- **Announcements** — `target_event` for event-scoped sends validated to belong to
  the same club; `sent?` is public; `target_event_belongs_to_club` private validation
- **rack-attack** — rate limiting: sign-in (5/20s), password reset (3/hr), magic link
  (10/min); custom 429 responder with `Retry-After` header
- **CSS injection prevention** — `Club.font_choice` validated against
  `ALLOWED_FONTS` allowlist (array literal to preserve "Playfair Display")
- **Design system** — Inter typography, gold (`#c8a96e`) primary color, consistent
  spacing scale, responsive layout; see `DESIGN.md`
- **RSpec test suite** — 164 examples covering models, request specs, mailers, and
  security paths; factories for all models; Capybara + Playwright for E2E
- **iCal export** — confirmed attendees can download `.ics` files for events
- **Development hosts** — regex allows all `*.lvh.me` subdomains for multi-tenant
  local testing (not just `baashb.lvh.me`)

### Changed

- Solid Cache, Queue, and Cable all share the primary PostgreSQL database — no separate
  Redis or SQLite DBs required in v1 (split to dedicated connections when throughput demands it)
- Password reset tokens are cryptographically signed JWTs with a 2-hour expiry, courtesy of
  Rails 8 `generates_token_for :password_reset` — no manual token column required

### Fixed

- N+1 queries on events index (`includes(:rsvps)`) and members index (aggregation query)
- Draft events no longer accessible via public `/events/:slug` URL (scoped to `.published`)
- Expired magic links are now cleaned up correctly — destroy call moved outside the
  transaction block so it actually commits (was silently swallowed by `ActiveRecord::Rollback`)
- `duplicate` action uses `save` instead of `save!` and returns a user-friendly error
  on failure; `starts_at` validation now conditional on published status
- Password reset mailer no longer hardcodes `lvh.me` — uses `ActionMailer::Base.default_url_options`
- Mailers now always include an explicit `from:` address (was missing on `MagicLinkMailer`
  and `RsvpConfirmationMailer`)
- Announcement "sent" status now renders correctly in the organizer dashboard (`sent?` was accidentally private)
- `contact_email` HTML injection in flash message eliminated — plain-text alert

