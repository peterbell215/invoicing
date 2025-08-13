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

    if (event.currentTarget.validity.valueMissing) {
        this.addValidationErrorText(event.currentTarget, "can't be blank");
    } else if (event.currentTarget.validity.typeMismatch) {
        this.addValidationErrorText(event.currentTarget, "is not a valid format");
    } else if (event.currentTarget.validity.patternMismatch) {
      this.addValidationErrorText(event.currentTarget, "format is invalid");
    } else if (event.currentTarget.validity.tooLong) {
      this.addValidationErrorText(event.currentTarget, "is too long");
    } else if (event.currentTarget.validity.tooShort) {
      this.addValidationErrorText(event.currentTarget, "is too short");
    } else if (event.currentTarget.validity.rangeOverflow) {
      this.addValidationErrorText(event.currentTarget, "is too high");
    } else if (event.currentTarget.validity.rangeUnderflow) {
      this.addValidationErrorText(event.currentTarget, "is too low");
    } else if (event.currentTarget.validity.stepMismatch) {
      this.addValidationErrorText(event.currentTarget, "is not a valid step");
    } else if (event.currentTarget.validity.badInput) {
      this.addValidationErrorText(event.currentTarget, "contains invalid characters");
    } else if (event.currentTarget.validity.customError) {
      this.addValidationErrorText(event.currentTarget, "is invalid");
    }
  }

  addValidationErrorText(field, errorMessage) {
    // Update error heading
    let heading = this.errorExplanationTarget.querySelector("h2");
    heading.innerText = `${this.numberOfValidationErrors} prohibited this record from being saved:`

    // Clear existing error messages
    const errorList = this.errorExplanationTarget.querySelector("ul");
    const errorItem = document.createElement("li");
    errorItem.textContent = `${field.labels[0].innerText} ${errorMessage}`;
    errorList.appendChild(errorItem);

    this.errorExplanationTarget.hidden = false;
  }

  resetValidationErrorText() {
    this.errorExplanationTarget.innerHTML = `<h2></h2> <ul></ul>`
    this.errorExplanationTarget.hidden = false;
    this.numberOfValidationErrors = 0;
  }
}
