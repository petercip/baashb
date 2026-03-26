class Announcement < ApplicationRecord
  include ClubScoped
  extend FriendlyId

  # Slug frozen after creation — protects archive URLs
  friendly_id :subject, use: [ :slugged, :scoped ], scope: :club

  def should_generate_new_friendly_id?
    slug.nil?
  end

  belongs_to :author, class_name: "Member"
  belongs_to :target_event, class_name: "Event", optional: true

  RECIPIENT_SCOPES = %w[ all_members event_attendees ].freeze

  validates :subject, :body, presence: true
  validates :recipient_scope, inclusion: { in: RECIPIENT_SCOPES }
  validates :target_event, presence: true, if: -> { recipient_scope == "event_attendees" }

  scope :sent,   -> { where.not(sent_at: nil).order(sent_at: :desc) }
  scope :drafts, -> { where(sent_at: nil) }

  def sent?
    sent_at.present?
  end
end
