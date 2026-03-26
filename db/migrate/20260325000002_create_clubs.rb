class CreateClubs < ActiveRecord::Migration[8.1]
  def change
    create_table :clubs do |t|
      # Identity
      t.string :name,         null: false
      t.string :slug,         null: false   # subdomain identifier (e.g. "baashb")
      t.string :contact_email               # shared alias for "Contact organizers" mailto

      # Branding (CSS custom property injection)
      t.string :primary_color, default: "#c8a96e"
      t.string :font_choice,   default: "Inter"

      # Custom domain + SSL
      t.string :custom_domain
      t.string :ssl_status,   default: "pending"   # pending | active | failed

      # Legal / 501c3 tax receipt fields
      t.string :legal_name          # IRS-registered name (may differ from display name)
      t.string :ein                 # Federal tax ID (XX-XXXXXXX)
      t.string :ca_registry_number  # California Registry of Charitable Trusts

      # Stripe keys (encrypted via Active Record Encryption)
      t.text :stripe_publishable_key
      t.text :stripe_secret_key
      t.text :stripe_webhook_secret

      # SMTP config (per-club overrides)
      t.string :smtp_host
      t.string :smtp_user
      t.text   :smtp_pass     # encrypted
      t.string :smtp_port, default: "587"
      t.string :smtp_from     # "From" address for outgoing email

      t.timestamps
    end

    add_index :clubs, :slug,          unique: true
    add_index :clubs, :custom_domain, unique: true, where: "custom_domain IS NOT NULL"
  end
end
