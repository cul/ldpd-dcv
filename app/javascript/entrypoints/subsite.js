// Base JavaScript for any DLC "subsite".  A "subsite" is a part of the app that
// has a route like "/catalog" or "/jay" and uses Blacklight search functionality.

// NOTE: window.jQuery and window.$ must be set globally (in a separate script) before this script
// is loaded. Blacklight 7 features requires jQuery to be available globally.

// Blacklight 7 features requires bootstrap.
import 'bootstrap';

// NOTE: In Blacklight 8, the import below will most likely change to: `import 'blacklight-frontend';`
import 'blacklight-frontend/app/assets/javascripts/blacklight/blacklight';

import { loadMirador } from '../src/features/mirador/mirador';
document.addEventListener('DOMContentLoaded', loadMirador);

import '../src/features/dcv/dcv';
import '../src/features/durst/durst';
import '../src/features/ifp/ifp';
import '../src/features/portrait/portrait';
import '../src/features/signature/signature';
import '../src/features/sites/sites';
import '../src/features/sites/edit.js';
import 'jquery-ui-dist/jquery-ui';

/****************************
 *  application.js
 ****************************/

// TODO: Are the two lines below still necessary?
// require.context('./assets', true)
// require.context('./images', true)


import '@ungap/url-search-params';

// leaflet, for maps
import L from 'leaflet';
delete L.Icon.Default.prototype._getIconUrl;

import markerIcon2x from 'leaflet/dist/images/marker-icon-2x.png';
import markerIcon from 'leaflet/dist/images/marker-icon.png';
import markerShadow from 'leaflet/dist/images/marker-shadow.png';

L.Icon.Default.mergeOptions({
  iconRetinaUrl: markerIcon2x,
  iconUrl: markerIcon,
  shadowUrl: markerShadow,
});


import 'leaflet.markercluster';
