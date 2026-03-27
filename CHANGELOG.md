# Changelog

All notable changes to baashb are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

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

- Consolidated Solid Cache, Queue, and Cable to share the primary PostgreSQL database
  (TODO: split to dedicated DBs as traffic grows)
- Password reset uses Rails 8 `generates_token_for :password_reset` (cryptographic JWT,
  no manual token column required)

### Fixed

- N+1 queries on events index (`includes(:rsvps)`) and members index (aggregation query)
- Draft events no longer accessible via public `/events/:slug` URL (scoped to `.published`)
- `magic_link.destroy` for expired links moved outside the transaction so it actually
  commits (previously rolled back with `ActiveRecord::Rollback`)
- `duplicate` action uses `save` instead of `save!` and returns a user-friendly error
  on failure; `starts_at` validation now conditional on published status
- Password reset mailer no longer hardcodes `lvh.me` — uses `ActionMailer::Base.default_url_options`
- Mailers now always include an explicit `from:` address (was missing on `MagicLinkMailer`
  and `RsvpConfirmationMailer`)
- `announce_controller` correctly renders `sent?` as public method (was accidentally private)
- `contact_email` HTML injection in flash message eliminated — plain-text alert

