import { ApplicationController } from './application_controller';

export class AutoSyncController extends ApplicationController {
  static targets = ['frequencyFields'];

  declare readonly frequencyFieldsTarget: HTMLElement;

  toggleEnabled(event: Event) {
    const checkbox = event.target as HTMLInputElement;
    this.frequencyFieldsTarget.classList.toggle('hidden', !checkbox.checked);
  }
}
