class CreateAnnouncements < ActiveRecord::Migration[8.1]
  def change
    create_table :announcements do |t|
      t.references :club,   null: false, foreign_key: true
      t.references :author, null: false, foreign_key: { to_table: :members }

      t.string :subject, null: false
      t.string :slug                      # friendly_id slug (scoped to club; frozen after creation)
      t.text   :body,    null: false      # plain text; wrapped in branded HTML at send time

      # Targeting
      t.string :recipient_scope, null: false, default: "all_members"
      #  all_members = all active club members
      #  event_attendees = confirmed attendees of a specific event
      t.references :target_event, foreign_key: { to_table: :events }

      # Delivery tracking
      t.datetime :sent_at                 # non-null = blast dispatched; nil = draft
      t.integer  :recipient_count         # stored at send time (denominator for delivery rate)

      t.timestamps
    end

    add_index :announcements, [ :club_id, :slug ], unique: true, where: "slug IS NOT NULL"
    add_index :announcements, [ :club_id, :sent_at ]
  end
end
