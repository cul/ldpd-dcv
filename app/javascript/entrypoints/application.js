import '@hotwired/turbo-rails';
import 'bootstrap';
import '@github/auto-complete-element';
import 'blacklight-frontend';
import '@columbia-libraries/cul-toolkit/setup';

import { makeCULmenu } from '@columbia-libraries/cul-toolkit';

const MENU_URL = 'https://toolkit.library.columbia.edu/v5/assets/cul-main-menu.json';

document.addEventListener('turbo:load', () => {
  makeCULmenu(MENU_URL);
  console.log('turbo:load event fired!');
});
