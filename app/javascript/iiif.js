import Mirador from "mirador";
import miradorDownloadPlugins from "mirador-dl-plugin";
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
        },
        miradorDownloadPlugin: {
          restrictDownloadOnSizeDefinition: true,
        }
      },
      [...miradorDownloadPlugins],
    );
  }
});