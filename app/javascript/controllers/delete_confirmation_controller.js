import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  open(event) {
    const id = event.currentTarget.getAttribute('data-id');
    const name = event.currentTarget.getAttribute('data-name');
    const entityType = event.currentTarget.getAttribute('data-entity-type') || 'item';

    // Dispatch custom event to be handled by delete_modal_controller
    const deleteEvent = new CustomEvent(`delete-${entityType}`, {
      bubbles: true,
      detail: {
        id: id,
        name: name,
        entityType: entityType
      }
    });

    document.dispatchEvent(deleteEvent);
  }
}
