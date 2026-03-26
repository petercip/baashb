class DropPasswordResetColumnsFromMembers < ActiveRecord::Migration[8.1]
  # Rails 8's has_secure_password auto-provides password reset tokens via
  # generates_token_for :password_reset (signed JWTs, no DB column needed).
  # The manual password_reset_token and password_reset_sent_at columns are removed.
  def change
    remove_index  :members, :password_reset_token, if_exists: true
    remove_column :members, :password_reset_token,   :string
    remove_column :members, :password_reset_sent_at, :datetime
  end
end
