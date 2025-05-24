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
    const errorContainer = this.errorExplanationTarget;

    // Update error heading
    let heading = errorContainer.querySelector("h2");

    if (heading == null) {
      errorContainer.innerHTML = `<h2></h2> <ul></ul>`
      heading = errorContainer.querySelector("h2");
    }

    heading.innerText = `${this.numberOfValidationErrors} prohibited this client from being saved:`

    // Clear existing error messages
    const errorList = errorContainer.querySelector("ul");
    const errorItem = document.createElement("li");
    errorItem.textContent = `${field.labels[0].innerText} can't be blank`;
    errorList.appendChild(errorItem);

    errorContainer.hidden = false;
  }
}
