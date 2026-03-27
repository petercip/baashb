class ClubMiddleware
  # Inserted before ActionDispatch::Session so Current.club is available
  # during session cookie processing and throughout the entire request.
  #
  # Resolution order (from plan):
  #   1. Exact custom_domain match  →  baash-b.org
  #   2. Subdomain slug fallback    →  baashb.lvh.me → slug "baashb"
  #   3. Neither matches            →  404
  #
  # Current.club is reset automatically at end of request by
  # ActiveSupport::CurrentAttributes lifecycle hooks.

  def initialize(app)
    @app = app
  end

  def call(env)
    # Pass health check through without club resolution — Kamal/Traefik probe by IP,
    # not by club domain, so the middleware would otherwise 404 the health endpoint.
    return @app.call(env) if env["PATH_INFO"] == "/up"

    host = env["HTTP_HOST"].to_s.split(":").first  # strip port

    club = Club.find_by(custom_domain: host)
    club ||= Club.find_by(slug: subdomain_from(host))

    if club
      Current.club = club
      @app.call(env)
    else
      not_found
    end
  end

  private

  def subdomain_from(host)
    # "baashb.lvh.me" → "baashb"
    # "baashb.example.com" → "baashb"
    # "localhost" → nil
    parts = host.split(".")
    parts.length >= 2 ? parts.first : nil
  end

  def not_found
    body = "<h1>Club not found</h1><p>No club is configured for this domain.</p>"
    [ 404, { "Content-Type" => "text/html" }, [ body ] ]
  end
end
