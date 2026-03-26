class Event < ApplicationRecord
  include ClubScoped
  extend FriendlyId

  # Slug frozen after creation — protects URLs in confirmation emails and iCal files
  friendly_id :name, use: [ :slugged, :scoped ], scope: :club

  def should_generate_new_friendly_id?
    slug.nil?  # only generate on creation; never regenerate on title edits
  end

  # Associations
  has_many :rsvps,   dependent: :destroy
  has_many :members, through: :rsvps

  # Status
  # ┌───────┐  publish  ┌───────────┐  cancel  ┌───────────┐
  # │ draft │──────────►│ published │─────────►│ cancelled │
  # └───────┘           └───────────┘           └───────────┘
  enum :status, { draft: "draft", published: "published", cancelled: "cancelled" }, default: "draft"

  # Validations
  validates :name, :starts_at, :venue, :capacity, presence: true
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :capacity,    numericality: { greater_than: 0, only_integer: true }

  # Scopes
  scope :upcoming,   -> { where("starts_at > ?", Time.current).order(:starts_at) }
  scope :past,       -> { where("starts_at <= ?", Time.current).order(starts_at: :desc) }
  scope :published,  -> { where(status: :published) }

  # Capacity helpers

  def free?
    price_cents == 0
  end

  def confirmed_count
    rsvps.confirmed.count
  end

  def spots_remaining
    [ capacity - confirmed_count, 0 ].max
  end

  def full?
    spots_remaining == 0
  end

  # FOMO label — returns nil if no urgency to show (>50% spots available)
  # Text tone: "3 spots remaining" (informational, not salesy)
  def fomo_label
    remaining = spots_remaining
    return nil if remaining > (capacity * 0.5).ceil
    return "Sold out" if remaining == 0
    "#{ remaining } #{ 'spot'.pluralize(remaining) } remaining"
  end

  # FOMO level — drives CSS class on capacity badge
  # :none (hidden), :neutral, :warning, :danger, :soldout
  def fomo_level
    remaining = spots_remaining
    if remaining == 0                        then :soldout
    elsif remaining == 1                     then :danger
    elsif remaining <= (capacity * 0.2).ceil then :warning
    elsif remaining <= (capacity * 0.5).ceil then :neutral
    else                                          :none
    end
  end

  def refund_cutoff_passed?
    refund_cutoff_at.present? && refund_cutoff_at < Time.current
  end
end
