class AddStripeChargeIdIndexToRsvps < ActiveRecord::Migration[8.1]
  def change
    add_index :rsvps, :stripe_charge_id,
              where: "stripe_charge_id IS NOT NULL",
              name: "index_rsvps_on_stripe_charge_id"
  end
end
