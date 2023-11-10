import Mirador from '@columbia-libraries/mirador/dist/es/src';
import miradorDownloadPlugins from "./src/iiif/mirador-downloaddialog";
import canvasLinkPlugin from './src/iiif/mirador-canvaslink';
import canvasRelatedLinksPlugin from './src/iiif/mirador-canvasRelatedLinks'
import citationSidebar from './src/iiif/mirador-citations';
import videoJSPlugin from './src/iiif/mirador-videojs';
import viewXmlPlugin from './src/iiif/mirador-viewXml';

$(document).ready(function(){
  var manifestUrl = $('#mirador').data('manifest');
  if (manifestUrl) {
    const startCanvas = function(queryParams) {
      if (queryParams.get("canvas")) {
        const canvases = queryParams.get("canvas").split(',');
        const canvas = canvases[0];
        return canvas.startsWith('../') ? manifestUrl.replace('/manifest', canvas.slice(2)) : canvas;
      } else return null;
    }(new URL(document.location).searchParams);
    Mirador.viewer(
      {
        id: 'mirador',
        window: {
          allowClose: false,
          allowFullscreen: true,
          panels: {
            info: true,
            canvas: true
          },
          canvasLink: {
            active: true,
            enabled: true,
            singleCanvasOnly: false,
            providers: [],
            getCanvasLink: (manifestId, canvases) => {
              const baseUri = window.location.href.replace(window.location.search, '');
              const canvasIndices = canvases.map(
                (canvas) => canvas.id.startsWith(manifestId.replace('/manifest', '')) ? '../canvas/' + canvas.id.split("/").slice(-2).join('/') : canvas.id,
              );
              return `${baseUri}?canvas=${canvasIndices.join(",",)}`;
            }
          },
        },
        windows: [
          { 
            manifestId: manifestUrl,
            canvasId: startCanvas,
          }
        ],
        workspace: {
          showZoomControls: true,
        },
        workspaceControlPanel: {
          enabled: false
        },
        miradorDownloadPlugin: {
          restrictDownloadOnSizeDefinition: true,
        }
      },
      [...miradorDownloadPlugins].concat([...canvasLinkPlugin]).concat([...viewXmlPlugin]).concat([...citationSidebar]).concat([...videoJSPlugin]).concat([...canvasRelatedLinksPlugin]),
    );
  }
});