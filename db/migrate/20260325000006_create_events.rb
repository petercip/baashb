class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.references :club, null: false, foreign_key: true

      t.string   :name,        null: false
      t.string   :slug                        # friendly_id slug (scoped to club; frozen after creation)
      t.text     :description
      t.datetime :starts_at,   null: false
      t.datetime :ends_at                     # nil = no fixed end time
      t.string   :venue,       null: false
      t.integer  :capacity,    null: false
      t.integer  :price_cents, null: false, default: 0   # 0 = free; check price_cents == 0, not a boolean
      t.datetime :refund_cutoff_at            # nil = no refund (or no refund needed for free events)
      t.string   :status,      null: false, default: "draft"  # draft | published | cancelled

      # Organizer event cancellation
      t.datetime :cancelled_at

      t.timestamps
    end

    add_index :events, [ :club_id, :slug ],     unique: true, where: "slug IS NOT NULL"
    add_index :events, [ :club_id, :status ]
    add_index :events, [ :club_id, :starts_at ]
  end
end
