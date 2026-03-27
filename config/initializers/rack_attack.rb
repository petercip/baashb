class Rack::Attack
  # ── Sign-in throttle ────────────────────────────────────────────────────────
  # Limit sign-in attempts to 5 per 20 seconds per IP.
  # Blocks credential stuffing without locking out a user who mistyped once.
  throttle("sign_in/ip", limit: 5, period: 20.seconds) do |req|
    req.ip if req.post? && req.path == "/sign-in"
  end

  # ── Password reset throttle ──────────────────────────────────────────────────
  # Limit to 3 reset requests per hour per IP — prevents email flooding.
  throttle("password_reset/ip", limit: 3, period: 1.hour) do |req|
    req.ip if req.post? && req.path == "/password-reset"
  end

  # ── Magic link throttle ──────────────────────────────────────────────────────
  # Limit magic link verification to 10 per minute per IP.
  # Mitigates token enumeration while accommodating legitimate use.
  throttle("magic_link/ip", limit: 10, period: 1.minute) do |req|
    req.ip if req.get? && req.path.start_with?("/auth/magic/")
  end

  # ── Throttled response ───────────────────────────────────────────────────────
  self.throttled_responder = lambda do |req|
    [
      429,
      { "Content-Type" => "text/plain", "Retry-After" => "60" },
      [ "Too many requests. Please wait a moment and try again." ]
    ]
  end
end
