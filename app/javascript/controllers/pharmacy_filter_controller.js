import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle(event) {
    const slug = event.target.value
    const row = document.getElementById(`pharmacy_${slug}_results`)
    if (row) row.style.display = event.target.checked ? "" : "none"
  }
}
