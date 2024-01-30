import {
  addNavMenu,
  addNavLink,
  addTextBlock,
  addFacetFieldFields,
  addSearchFieldFields,
  addScopeFilterFields,
  addValueFieldsetFromTemplate,
  removeNavMenu,
  removeNavLink,
  removeTextBlock,
  onReady,
} from './src/sites/edit';

window.addNavMenu = addNavMenu;
window.addNavLink = addNavLink;
window.addTextBlock = addTextBlock;
window.addFacetFieldFields = addFacetFieldFields;
window.addSearchFieldFields = addSearchFieldFields;
window.addScopeFilterFields = addScopeFilterFields;
window.addValueFieldsetFromTemplate = addValueFieldsetFromTemplate;
window.removeNavMenu = removeNavMenu;
window.removeNavLink = removeNavLink;
window.removeTextBlock = removeTextBlock;
$(document).ready(onReady);
