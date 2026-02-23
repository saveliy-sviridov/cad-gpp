import { httpRequest } from '@utils';
import { ApplicationController } from './application_controller';

const DEBOUNCE_DELAY = 1000;
const TIMEOUT_DELAY = 60000;

export class ChampNoteController extends ApplicationController {
  static targets = ['textarea'];
  static values = {
    url: String
  };

  declare readonly textareaTarget: HTMLTextAreaElement;
  declare readonly urlValue: string;

  onInput() {
    this.debounce(this.save, DEBOUNCE_DELAY);
  }

  private save() {
    const body = this.textareaTarget.value;
    const formData = new FormData();
    formData.append('champ_note[body]', body);

    this.globalDispatch('autosave:enqueue');

    httpRequest(this.urlValue, {
      method: 'patch',
      body: formData,
      timeout: TIMEOUT_DELAY
    })
      .turbo()
      .then(() => {
        this.globalDispatch('autosave:end');
      })
      .catch(() => {
        this.globalDispatch('autosave:error');
      });
  }
}
