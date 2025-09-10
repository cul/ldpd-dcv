import Mirador from '@columbia-libraries/mirador';
import { __CLIENT_INTERNALS_DO_NOT_USE_OR_WARN_USERS_THEY_CANNOT_UPGRADE as ReactSharedInternalsClient } from 'react';

const culMiradorPlugins = [...Mirador.culPlugins.downloadDialogPlugin]
  .concat([...Mirador.culPlugins.viewXmlPlugin])
  .concat([...Mirador.culPlugins.citationsSidebarPlugin])
  .concat([...Mirador.culPlugins.videojsPlugin])
  .concat([...Mirador.culPlugins.canvasRelatedLinksPlugin])
  .concat([...Mirador.culPlugins.hintingSideBar])
  .concat([...Mirador.culPlugins.viewerNavigation])
  .concat([...Mirador.culPlugins.nativeObjectViewerPlugin]);

$(document).ready(function () {
  const miradorDiv = $('#mirador');
  const manifestUrl = miradorDiv.data('manifest');
  if (manifestUrl) {
    const numChildren = miradorDiv.data('num-children');
    const startCanvas = function (queryParams) {
      if (queryParams.get("canvas")) {
        const canvases = queryParams.get("canvas").split(',');
        const canvas = canvases[0];
        return canvas.startsWith('../') ? manifestUrl.replace('/manifest', canvas.slice(2)) : canvas;
      } else return null;
    }(new URL(document.location).searchParams);
    const viewConfig = {
      defaultView: 'single',
      views: [
        { key: 'single', behaviors: ['individuals'] },
        { key: 'book', behaviors: ['paged'] },
        { key: 'scroll', behaviors: ['continuous'] },
        { key: 'gallery', behaviors: ['continuous', 'individuals', 'paged', 'unordered'] },
      ],
    };
    if (numChildren && numChildren === 1) {
      viewConfig.views = [
        { key: 'single' }
      ];
      viewConfig.defaultView = 'single';
    }
    const foldersAttValue = miradorDiv.data('use-folders');
    const useFolders = (new Boolean(foldersAttValue).valueOf() && !String.toString(foldersAttValue).match(/false/i));
    if (useFolders) {
      culMiradorPlugins.push([...Mirador.culPlugins.collectionFoldersPlugin]);
      viewConfig.allowTopCollectionButton = true;
      viewConfig.sideBarOpen = true;
    }

    ReactSharedInternalsClient.actQueue = null;

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
        osdConfig: {
          preserveViewport: false,
        },
        translations: {
          en: { openCompanionWindow_citation: "Citation" },
        },
      },
      culMiradorPlugins,
    );
  }
});
