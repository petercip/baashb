import { Controller } from "@hotwired/stimulus"

// Keeps the "Total due today" display in sync as the user types a donation amount.
//
// Usage:
//   data-controller="donation-total"
//   data-donation-total-ticket-price-value="<price_cents>"  (integer, cents)
//   data-donation-total-target="donationInput"              (the donation number input)
//   data-donation-total-target="display"                    (the total span)
//   data-action="input->donation-total#update"              (on the donation input)
export default class extends Controller {
  static targets = ["donationInput", "display"]
  static values  = { ticketPrice: Number }

  update() {
    const donationDollars = parseFloat(this.donationInputTarget.value) || 0
    const donationCents   = Math.round(donationDollars * 100)
    const totalCents      = this.ticketPriceValue + donationCents

    this.displayTarget.textContent = this.#formatCurrency(totalCents / 100)
  }

  #formatCurrency(amount) {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: "USD"
    }).format(amount)
  }
}
