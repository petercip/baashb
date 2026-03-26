# TODOS

## Infrastructure

### Separate Solid Queue job server when volume grows

**What:** Uncomment the job server in `config/deploy.yml` and set `SOLID_QUEUE_IN_PUMA=false`.

**Why:** Currently Solid Queue runs inside Puma (SOLID_QUEUE_IN_PUMA=true). Under load (e.g. 500-member email blast), background jobs compete with web requests for Puma threads, increasing response latency.

**Context:** Accepted trade-off for v1 — BAASH-B's scale doesn't justify the extra container. When the platform hosts clubs with 200+ members sending regular blasts, split the job process. Change: uncomment `job:` section in `config/deploy.yml`, set `SOLID_QUEUE_IN_PUMA=false` in env config, add `bin/jobs` entrypoint.

**Effort:** S
**Priority:** P3
**Depends on:** None

---

## Features

### Annual dues / membership billing

**What:** Allow clubs to charge recurring annual membership fees via Stripe Subscriptions.

**Why:** BAASH-B doesn't charge dues, but other clubs on the platform may want this.

**Context:** Deferred in CEO review scope decisions. Would require a `Subscription` model, Stripe Subscription integration (separate from Checkout), dunning logic for failed payments, and a grace period UX. Non-trivial Stripe integration distinct from the one-time payment flow.

**Effort:** L
**Priority:** P3
**Depends on:** Core platform shipped and running

---

### Photo gallery per event

**What:** Organizers can upload post-event photos; members can view them.

**Why:** Creates lasting memories and community history for each event.

**Context:** Deferred — BAASH-B members prefer not being photographed. When added: Active Storage for uploads, image_processing for thumbnails, per-event gallery page. Consider privacy controls (members only, or organizer-curated visible set).

**Effort:** M
**Priority:** P4
**Depends on:** None

---

### Font picker UI for club branding

**What:** A UI for organizers to select from a curated list of fonts for their club's branding.

**Why:** Club branding currently supports `font_choice` as a stored field but has no picker UI.

**Context:** `font_choice` is stored on the Club model and injected as CSS custom properties. The picker would be part of the club settings page. Curate a list of 5-8 web-safe or Google Fonts options. The CSS injection already handles whichever font is stored.

**Effort:** S
**Priority:** P4
**Depends on:** Club settings page


---

### Waitlist for sold-out events

**What:** Let members join a waitlist; automatically notify and offer the spot when someone cancels.

**Why:** Currently, sold-out events are closed permanently. A waitlist recaptures demand and reduces the feeling of exclusion.

**Context:** Explicitly out of scope for v1 (no waitlist, first-come-first-served). Complexity: spot-hold TTL, notification email, accepting/declining the offer, preventing double-booking. Model additions: `Waitlist` join table, state machine for offer lifecycle.

**Effort:** M
**Priority:** P3
**Depends on:** Core RSVP + cancellation flow

---

## Deployment & Operations

### Custom domain SSL troubleshooting guide in README

**What:** Document the ACME HTTP-01 challenge failure modes and recovery steps for club operators.

**Why:** When a club sets a custom domain, Traefik must complete an ACME challenge. This fails if: DNS hasn't propagated yet, a reverse proxy strips `.well-known/acme-challenge`, or the server isn't reachable on port 80.

**Context:** The `ssl_status: failed` state will be hit by non-expert operators. README should explain: how to verify DNS propagation (dig/nslookup), how to check the Traefik ACME log, how to reset `ssl_status` to `pending` to trigger a retry, and the HTTP-01 port 80 requirement.

**Effort:** S
**Priority:** P1
**Depends on:** Custom domain feature shipped

---

### SPF / DKIM / DMARC setup documentation

**What:** Document the DNS records clubs need to configure for email deliverability when sending from their own domain.

**Why:** Without SPF/DKIM, emails from `events@baash-b.org` land in spam. This is critical for invite emails and event confirmations.

**Context:** Recommend a transactional email provider (Postmark or SendGrid) that handles DKIM signing. Club operator needs to add SPF TXT record and DKIM CNAME records to their DNS. Document per-provider. Also document bounce handling (how to know when an email address is invalid).

**Effort:** S
**Priority:** P1
**Depends on:** SMTP configuration shipped

---

### ssl_status recovery UX in organizer settings

**What:** Show `ssl_status` (pending/active/failed) in the club settings page with a "Retry" button on failure.

**Why:** Organizers have no visibility into whether their custom domain SSL certificate is working. A failed cert means their members can't access the site via the custom domain.

**Context:** The `ssl_status` field exists on Club. The settings page should show a status indicator and a "Retry SSL provisioning" button (sets `ssl_status: :pending`, rewrites Traefik config entry). Full retry/recovery UX deferred from CEO review.

**Effort:** S
**Priority:** P2
**Depends on:** Club settings page + custom domain feature

---

## Legal / Compliance

### 501c3 receipt template legal sign-off

**What:** Have BAASH-B's treasurer or accountant review and approve the donation receipt email template wording before the first production receipt is sent.

**Why:** Donation receipts are a legal document. The IRS requires specific language. Incorrect language (or missing EIN / CA Registry number) could disqualify donations for tax purposes.

**Context:** The template uses: "No goods or services were provided in exchange for this contribution." Club's `legal_name`, `ein`, and `ca_registry_number` are required fields before receipts can be sent. `club.receipt_configured?` gates the feature. Get sign-off from BAASH-B's accountant before enabling for production.

**Effort:** XS (review only, no code)
**Priority:** P0 (block on first receipt send)
**Depends on:** Receipt email template implemented

## Completed

<!-- Move completed items here with: **Completed:** vX.Y.Z (YYYY-MM-DD) -->
