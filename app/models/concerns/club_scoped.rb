module ClubScoped
  extend ActiveSupport::Concern

  included do
    belongs_to :club
    validates :club, presence: true

    # RULE: never use default_scope. Controllers always query via current_club.events,
    # current_club.members, etc. This concern only provides the association + validation.
  end
end
