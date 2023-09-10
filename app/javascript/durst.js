import { durstReady, scrollToBottomOfPage } from './src/durst/durst.general';

window.scrollToBottomOfPage = scrollToBottomOfPage;

$(document).ready(durstReady);
