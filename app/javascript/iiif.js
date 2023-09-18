import Mirador from 'mirador/dist/es/src/index';
import miradorDownloadPlugins from "mirador-downloaddialog";
import canvasLinkPlugin from 'mirador-canvaslink/es';
import citationSidebar from './src/iiif/mirador-citations';
import viewXmlPlugin from './src/iiif/mirador-viewXml';
import ShareCanvasLinkDialog from './src/iiif/mirador-canvaslink/components/ShareCanvasLinkDialog';

canvasLinkPlugin[1].component = ShareCanvasLinkDialog;
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
      [...miradorDownloadPlugins].concat([...canvasLinkPlugin]).concat([...viewXmlPlugin]).concat([...citationSidebar]),
    );
  }
});