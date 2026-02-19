import OHSynchronizer from './widget.js';

window.OHSynchronizer = OHSynchronizer;
window.dispatchEvent(new Event('ohsynchronizer:ready'));
