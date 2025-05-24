import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["errorExplanation"]

  numberOfValidationErrors = 0;

  connect() {
  }

  markFieldAsInvalid(event) {
    event.preventDefault();

    this.numberOfValidationErrors++;
    event.target.classList.add("field-with-error");

    this.addValidationErrorText(event.target);
  }

  addValidationErrorText(field) {
    // Update error heading
    let heading = this.errorExplanationTarget.querySelector("h2");
    heading.innerText = `${this.numberOfValidationErrors} prohibited this client from being saved:`

    // Clear existing error messages
    const errorList = this.errorExplanationTarget.querySelector("ul");
    const errorItem = document.createElement("li");
    errorItem.textContent = `${field.labels[0].innerText} can't be blank`;
    errorList.appendChild(errorItem);

    errorContainer.hidden = false;
  }

  resetValidationErrorText() {
    this.errorExplanationTarget.innerHTML = `<h2></h2> <ul></ul>`
    this.errorExplanationTarget.hidden = false;
    this.numberOfValidationErrors = 0;
  }
}
