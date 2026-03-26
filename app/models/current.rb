class Current < ActiveSupport::CurrentAttributes
  attribute :club     # set by ClubMiddleware from Host header
  attribute :session  # set by Authentication concern
  attribute :member   # delegated from session by Authentication concern
end
