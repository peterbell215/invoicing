import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  open(event) {
    const id = event.currentTarget.getAttribute('data-id');
    const name = event.currentTarget.getAttribute('data-name');

    // Extract entity type from button class (e.g., delete-client-btn -> client)
    const buttonClasses = event.currentTarget.className;
    const entityMatch = buttonClasses.match(/delete-(\w+)-btn/);
    const entityType = entityMatch ? entityMatch[1] : 'item';

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
