import { updateWindow } from "mirador/dist/es/src/state/actions";
import { getContainerId } from "mirador/dist/es/src/state/selectors";
import { getManifestUrl } from "mirador/dist/es/src/state/selectors/manifests";

import { WindowSideBarCitationButton } from './WindowSideBarCitationButton';
import { WindowSideBarCitationPanel } from './WindowSideBarCitationPanel';
import { getPluginConfig } from "./state/selectors";

export {
  WindowSideBarCitationButton,
  WindowSideBarCitationPanel,
};

export default [
  {
    component: WindowSideBarCitationButton,
    config: {},
    mapDispatchToProps: (dispatch, { windowId }) => ({
      updateConfig: function(openPanel) {
        return dispatch(updateWindow(windowId, { openPanel }))
      }
    }),
    mapStateToProps: (state, { windowId }) => ({
      containerId: getContainerId(state),
      config: getPluginConfig(state, { windowId }),
    }),
    mode: "add",
    name: "WindowSideBarCitationButton",
    target: "WindowSideBarButtons",
  },
  {
    component: WindowSideBarCitationPanel,
    config: {},
    mapDispatchToProps: (dispatch, { windowId }) => ({
      updateConfig: function(openPanel) {
        return dispatch(updateWindow(windowId, { openPanel }))
      }
    }),
    mapStateToProps: (state, { windowId }) => ({
      containerId: getContainerId(state),
      manifestId: getManifestUrl(state, { windowId }),
      config: getPluginConfig(state, { windowId }),
    }),
    // see mirador/dist/es/src/extend/pluginMapping.js
    companionWindowKey: WindowSideBarCitationButton.value,
    name: "WindowSideBarCitationPanel",
  },
];
