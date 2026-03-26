class Rsvp < ApplicationRecord
  belongs_to :event
  belongs_to :member

  # Status state machine
  # ┌─────────────────┐  webhook: checkout.session.completed  ┌───────────┐
  # │ pending_payment │ ─────────────────────────────────────►│ confirmed │
  # │  (Stripe async) │                                        │           │
  # └────────┬────────┘                                        └─────┬─────┘
  #          │                                                        │
  #  checkout.session.expired / cleanup job                   member cancel
  #  or oversell refund                                        or org cancel
  #          │                                                        │
  #          ▼                                                        ▼
  #       [deleted]                                             cancelled
  #
  # Free events: created directly as :confirmed (no Stripe, no pending_payment state)
  enum :status, {
    pending_payment: "pending_payment",
    confirmed:       "confirmed",
    cancelled:       "cancelled"
  }, default: "confirmed"

  # Refund status (nil = no refund attempted or not applicable)
  # Keys already include the "refund_" prefix so methods are rsvp.refund_pending? etc.
  enum :refund_status, {
    refund_pending:   "pending",
    refund_succeeded: "succeeded",
    refund_failed:    "failed"
  }

  # Scopes
  scope :confirmed,       -> { where(status: :confirmed) }
  scope :pending_payment, -> { where(status: :pending_payment) }

  # Validations
  validates :event, :member, presence: true
  validates :member_id, uniqueness: { scope: :event_id }

  # Cancel button only shown after paid_at is set (prevents race with incoming webhook)
  def cancellable_by_member?
    confirmed? && paid_at.present? && !event.refund_cutoff_passed?
  end

  def cancellable_by_organizer?
    confirmed?
  end
end
