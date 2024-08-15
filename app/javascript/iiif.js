import Mirador from '@columbia-libraries/mirador/dist/es/src';
import miradorDownloadPlugins from '@columbia-libraries/mirador/dist/es/src/culPlugins/mirador-downloaddialog';
import canvasRelatedLinksPlugin from '@columbia-libraries/mirador/dist/es/src/culPlugins/mirador-canvasRelatedLinks'
import citationSidebar from '@columbia-libraries/mirador/dist/es/src/culPlugins/mirador-citations';
import hintingSidebar from '@columbia-libraries/mirador/dist/es/src/culPlugins/mirador-hinting-sidebar';
import videoJSPlugin from '@columbia-libraries/mirador/dist/es/src/culPlugins/mirador-videojs';
import viewerNavigation from '@columbia-libraries/mirador/dist/es/src/culPlugins/mirador-pageIconViewerNavigation';
import viewXmlPlugin from '@columbia-libraries/mirador/dist/es/src/culPlugins/mirador-viewXml';

const flattenPluginConfigs = (...plugins) => plugins.reduce(
  (acc, curr) => {
    return acc.concat([...curr])
  }, []
);

$(document).ready(function(){
  const manifestUrl = $('#mirador').data('manifest');
  if (manifestUrl) {
    const numChildren = $('#mirador').data('num-children');
    const startCanvas = function(queryParams) {
      if (queryParams.get("canvas")) {
        const canvases = queryParams.get("canvas").split(',');
        const canvas = canvases[0];
        return canvas.startsWith('../') ? manifestUrl.replace('/manifest', canvas.slice(2)) : canvas;
      } else return null;
    }(new URL(document.location).searchParams);
    const viewConfig = {};
    if (numChildren && numChildren === 1) {
      viewConfig.views = [
        { key: 'single' }
      ];
      viewConfig.defaultView = 'single';
    }
    Mirador.viewer(
      {
        id: 'mirador',
        window: {
          allowClose: false,
          allowFullscreen: true,
          allowMaximize: false,
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
          ...viewConfig,
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
        },
        translations: {
          en: { openCompanionWindow_citation: "Citation" },
        },
      },
      flattenPluginConfigs(canvasRelatedLinksPlugin, citationSidebar, hintingSidebar, miradorDownloadPlugins, videoJSPlugin, viewerNavigation, viewXmlPlugin),
    );
  }
});