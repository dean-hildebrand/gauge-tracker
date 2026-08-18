import { Controller } from "@hotwired/stimulus"

// One instance per flash message. A message with a dismiss-after value clears
// itself; the rest wait for the user to click the close button.
export default class extends Controller {
  static values = { dismissAfter: { type: Number, default: 0 } }

  connect() {
    if (this.dismissAfterValue > 0) {
      this.timeout = setTimeout(() => this.close(), this.dismissAfterValue)
    }
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  close() {
    clearTimeout(this.timeout)

    // Collapse the list wrapper too, so its margin does not leave a gap behind.
    const list = this.element.parentElement
    this.element.remove()
    if (list && list.childElementCount === 0) list.remove()
  }
}
