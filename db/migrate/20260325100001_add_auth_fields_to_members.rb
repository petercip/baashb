class AddAuthFieldsToMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :members, :password_digest,        :string
    add_column :members, :google_uid,             :string
    add_column :members, :password_reset_token,   :string
    add_column :members, :password_reset_sent_at, :datetime

    # google_uid is unique per club (a Google account can have one membership per club)
    add_index :members, %i[club_id google_uid],
              unique: true,
              where: "google_uid IS NOT NULL",
              name: "index_members_on_club_id_and_google_uid"

    # password_reset_token must be globally unique (used as URL token)
    add_index :members, :password_reset_token,
              unique: true,
              where: "password_reset_token IS NOT NULL"
  end
end
