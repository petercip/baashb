module Authentication
  extend ActiveSupport::Concern

  included do
    # resume_session always runs — even for public pages — so current_member
    # is populated from the cookie regardless of whether auth is required.
    before_action :resume_session
    # require_authentication redirects to sign-in if session could not be resumed.
    before_action :require_authentication
    helper_method :current_member, :current_club, :organizer?
  end

  private

  def current_member
    Current.member
  end

  def current_club
    Current.club
  end

  def organizer?
    current_member&.organizer?
  end

  def require_authentication
    redirect_to_sign_in unless current_member
  end

  # Attempt to resume an existing session from the signed cookie.
  # Returns truthy if session was resumed, nil/false if not.
  def resume_session
    token = cookies.signed[:session_token]
    return unless token.present?

    session_record = Session.find_by(token: token)
    return unless session_record
    return if session_record.expired?

    member = session_record.member
    return unless member.active?            # immediately lock out removed members
    return unless member.club_id == Current.club&.id  # defense-in-depth: session must belong to current club

    Current.session = session_record
    Current.member  = member
    true
  end

  def start_new_session_for(member, request)
    session_record = member.sessions.create!(
      expires_at: Session::SESSION_TTL.from_now,
      user_agent: request.user_agent,
      ip_address: request.remote_ip
    )
    cookies.signed[:session_token] = {
      value:     session_record.token,
      expires:   Session::SESSION_TTL.from_now,
      httponly:  true,
      same_site: :lax
    }
    Current.session = session_record
    Current.member  = member
  end

  def terminate_session
    Current.session&.destroy
    cookies.delete(:session_token)
    Current.session = nil
    Current.member  = nil
  end

  def redirect_to_sign_in
    session[:return_to] = request.fullpath if request.get? || request.head?
    redirect_to new_session_path, alert: "Please sign in to continue."
  end

  def after_sign_in_path
    session.delete(:return_to).presence || root_path
  end
end
