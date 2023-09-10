import Mirador from "mirador";
import ArchivalIIIFViewer from "@archival-iiif/viewer-react";
$(document).ready(function(){
  var manifestUrl = $('#mirador').data('manifest');
  if (manifestUrl) {
    Mirador.viewer(
      {
        id: 'mirador',
        window: {
          allowClose: false,
          allowFullscreen: true,
          panels: {
            info: true,
            canvas: true
          }
        },
        windows: [
          { manifestId: manifestUrl }
        ],
        workspace: {
          showZoomControls: true,
        },
        workspaceControlPanel: {
          enabled: false
        }
      }
    );
  }
  var manifestUrl = $('#aiiif').data('manifest');
  if (manifestUrl) {
    new ArchivalIIIFViewer({id: 'aiiif', manifest: manifestUrl});
  }
});