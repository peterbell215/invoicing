import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "form", "name"]
  static values = { entity: String }

  connect() {
    // Listen for delete events for different entity types
    this.boundHandlers = {};
    const entityTypes = ['payee', 'client', 'message'];

    entityTypes.forEach(entityType => {
      this.boundHandlers[entityType] = this.handleDeleteRequest.bind(this);
      document.addEventListener(`delete-${entityType}`, this.boundHandlers[entityType]);
    });
  }

  disconnect() {
    // Clean up event listeners when controller is disconnected
    Object.keys(this.boundHandlers).forEach(entityType => {
      document.removeEventListener(`delete-${entityType}`, this.boundHandlers[entityType]);
    });
  }

  handleDeleteRequest(event) {
    const { id, name } = event.detail;
    const entityType = event.type.replace('delete-', '');

    // Set the entity name in the dialog
    this.nameTarget.textContent = name;

    // Set the form action based on entity type
    this.formTarget.action = `/${entityType}s/${id}`;

    // Show the dialog
    this.dialogTarget.showModal();
  }

  close() {
    this.dialogTarget.close();
  }

  clickOutside(event) {
    if (event.target === this.dialogTarget) {
      this.dialogTarget.close();
    }
  }
}
