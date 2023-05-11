import Mirador from "mirador";

$(document).ready(function(){
  const manifestUrl = $('#mirador').data('manifest');
  var miradorInstance = Mirador.viewer(
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
});