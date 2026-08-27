import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["scroll"]

  prev() {
    this.scrollTarget.scrollBy({ left: -this.#scrollAmount(), behavior: "smooth" })
  }

  next() {
    this.scrollTarget.scrollBy({ left: this.#scrollAmount(), behavior: "smooth" })
  }

  #scrollAmount() {
    const card = this.scrollTarget.querySelector(".product-card")
    return card ? card.offsetWidth + 16 : 200
  }
}
