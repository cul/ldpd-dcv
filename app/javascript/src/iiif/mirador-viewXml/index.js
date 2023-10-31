import { updateWindow } from "@columbia-libraries/mirador/dist/es/src/state/actions";
import { getContainerId } from "@columbia-libraries/mirador/dist/es/src/state/selectors";
import { getManifestUrl } from "@columbia-libraries/mirador/dist/es/src/state/selectors/manifests";

import MiradorViewXmlPlugin from './MiradorViewXmlPlugin';
import MiradorViewXmlDialog from './MiradorViewXmlDialog';
import { getManifestSeeAlso, getPluginConfig } from "./state/selectors";

export {
  MiradorViewXmlPlugin,
  MiradorViewXmlDialog,
};

export default [
  {
    component: MiradorViewXmlPlugin,
    config: {},
    mapDispatchToProps: (dispatch, { windowId }) => ({
      updateConfig: function(viewXmlDialog) {
        return dispatch(updateWindow(windowId, { viewXmlDialog }))
      }
    }),
    mapStateToProps: (state, { windowId }) => ({
      containerId: getContainerId(state),
      config: getPluginConfig(state, { windowId }),
    }),
    mode: "add",
    name: "MiradorViewXmlPlugin",
    target: "WindowTopBarPluginArea",
  },
  {
    component: MiradorViewXmlDialog,
    config: {},
    mapDispatchToProps: (dispatch, { windowId }) => ({
      updateConfig: function(viewXmlDialog) {
        return dispatch(updateWindow(windowId, { viewXmlDialog }))
      }
    }),
    mapStateToProps: (state, { windowId }) => ({
      containerId: getContainerId(state),
      manifestId: getManifestUrl(state, { windowId }),
      seeAlso: getManifestSeeAlso(state, { windowId }),
      config: getPluginConfig(state, { windowId }),
    }),
    mode: "add",
    name: "MiradorViewXmlDialog",
    target: "Window",
  },
];
