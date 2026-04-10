Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # ── Authentication ──────────────────────────────────────────────────────────

  # Email / password sign-in
  get    "/sign-in",  to: "sessions#new",     as: :new_session
  post   "/sign-in",  to: "sessions#create",  as: :session
  delete "/sign-out", to: "sessions#destroy", as: :sign_out

  # Password reset
  get   "/password-reset",        to: "password_resets#new",    as: :new_password_reset
  post  "/password-reset",        to: "password_resets#create", as: :password_resets
  get   "/password-reset/:token", to: "password_resets#edit",   as: :edit_password_reset
  patch "/password-reset/:token", to: "password_resets#update", as: :password_reset

  # Google OAuth
  # POST /auth/google          → handled by OmniAuth middleware (no route needed)
  # GET  /auth/google/callback → Google redirects here after auth
  get  "/auth/google/callback", to: "omniauth_callbacks#google"
  post "/auth/google/callback", to: "omniauth_callbacks#google"
  get  "/auth/failure",         to: "omniauth_callbacks#failure"

  # Legacy magic-link invite route (organizer onboarding — kept for Path 1)
  get "/auth/magic/:token", to: "magic_links#verify", as: :magic_link_verify

  # ── Member-facing ───────────────────────────────────────────────────────────

  # Events (index = auth-gated members-only list; show = public shareable page)
  resources :events, param: :slug, only: %i[index show] do
    member do
      get  :rsvp,  to: "rsvps#new",    as: :new_rsvp  # paid events: donation form
      post :rsvps, to: "rsvps#create", as: :rsvp      # both: create RSVP / start Stripe checkout
      get  "calendar.ics", to: "events#calendar", as: :calendar
    end
  end

  # RSVP cancellation (shallow: member owns the RSVP)
  delete "/rsvps/:id", to: "rsvps#destroy", as: :rsvp

  # Stripe webhook receiver and post-checkout return landing
  post "/stripe/webhooks",        to: "stripe_webhooks#create",  as: :stripe_webhooks
  get  "/stripe/checkout/return", to: "stripe_checkouts#return", as: :stripe_checkout_return

  # Member profiles
  resources :members, param: :slug, only: %i[show]

  # Announcement archive
  resources :announcements, param: :slug, only: %i[index show]

  # ── Organizer ───────────────────────────────────────────────────────────────

  namespace :organizer do
    root to: "dashboard#index"

    resources :events, param: :slug do
      member do
        post :duplicate
        post :cancel
        post :publish
        get  :attendees
      end
      resources :rsvps, only: :destroy  # DELETE /organizer/events/:slug/rsvps/:id
    end

    resources :members, param: :slug
    resources :announcements, param: :slug

    get   "settings", to: "settings#show",   as: :settings
    patch "settings", to: "settings#update"
  end

  # ── Root ──────────────────────────────────────────────────────────────────

  # Signed-out: club landing page. Signed-in: redirected to events (in HomeController).
  root to: "home#index"
end
