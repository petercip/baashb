class CreateMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :members do |t|
      t.references :club, null: false, foreign_key: true

      t.string :email, null: false
      t.string :name,  null: false
      t.string :slug             # friendly_id slug (scoped to club)
      t.string :bio
      t.string :role,   null: false, default: "member"     # member | organizer
      t.string :status, null: false, default: "pending"    # pending | active | removed

      # Signup request (Path 2: self-signup)
      t.text   :signup_message          # message submitted during signup request
      t.string :verification_token      # email verification token (24h TTL)
      t.datetime :verification_sent_at
      t.datetime :verified_at

      t.timestamps
    end

    add_index :members, [ :club_id, :email ], unique: true
    add_index :members, [ :club_id, :slug ],  unique: true, where: "slug IS NOT NULL"
    add_index :members, :verification_token,  unique: true, where: "verification_token IS NOT NULL"
  end
end
