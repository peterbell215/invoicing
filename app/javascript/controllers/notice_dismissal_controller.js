import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["notice"]
  static values = {
    autoDismissAfter: { type: Number, default: 5000 } // 5 seconds by default
  }

  connect() {
    if (this.hasNoticeTarget && this.noticeTarget.innerHTML.trim() !== '') {
      this.autoDismissTimeout = setTimeout(this.dismiss.bind(this), this.autoDismissAfterValue)
    }
  }

  dismiss() {
    if (this.hasNoticeTarget) {
      this.noticeTarget.style.opacity = '0'
      
      // After the fade animation completes, hide the element
      setTimeout(() => {
        this.noticeTarget.innerHTML = ''
        this.noticeTarget.style.opacity = '1'
      }, 300)
    }
  }

  disconnect() {
    if (this.autoDismissTimeout) {
      clearTimeout(this.autoDismissTimeout)
    }
  }
}