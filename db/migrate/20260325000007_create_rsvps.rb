class CreateRsvps < ActiveRecord::Migration[8.1]
  def change
    create_table :rsvps do |t|
      t.references :event,  null: false, foreign_key: true
      t.references :member, null: false, foreign_key: true

      # RSVP lifecycle
      # ┌─────────────────────────────────────────────────────────────────┐
      # │  pending_payment ──(webhook confirmed)──► confirmed             │
      # │        │                                     │                  │
      # │        │  (checkout expired / abandoned)     │ (member cancel   │
      # │        ▼                                     │  or org cancel)  │
      # │     [deleted]                                ▼                  │
      # │                                          cancelled              │
      # └─────────────────────────────────────────────────────────────────┘
      t.string   :status,         null: false, default: "confirmed"
      #  pending_payment = Stripe Checkout created; capacity held
      #  confirmed       = webhook received (or instant for free events)
      #  cancelled       = member or organizer cancelled

      # Stripe fields (null for free events)
      t.string   :checkout_session_id     # Stripe Checkout Session ID
      t.string   :stripe_charge_id        # charge / payment_intent ID (from webhook)
      t.integer  :amount_paid_cents       # ticket price at time of payment
      t.integer  :donation_amount_cents, default: 0
      t.datetime :paid_at                 # set on webhook; cancel button gated on this

      # Refund tracking (null = not refunded / not applicable)
      t.string   :refund_status           # pending | succeeded | failed
      t.string   :stripe_refund_id
      t.datetime :refunded_at

      # Donation receipt
      t.datetime :receipt_sent_at         # non-null = receipt already sent (idempotency guard)

      # Cancellation
      t.datetime :cancelled_at

      t.timestamps
    end

    add_index :rsvps, [ :event_id, :member_id ], unique: true
    add_index :rsvps, :checkout_session_id, unique: true, where: "checkout_session_id IS NOT NULL"
    add_index :rsvps, [ :event_id, :status ]
  end
end
