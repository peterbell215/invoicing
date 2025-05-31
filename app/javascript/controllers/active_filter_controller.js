import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox"]

  toggle() {
    const url = new URL(window.location.href)
    url.searchParams.set('active_only', this.checkboxTarget.checked)
    Turbo.visit(url.toString())
  }
}
