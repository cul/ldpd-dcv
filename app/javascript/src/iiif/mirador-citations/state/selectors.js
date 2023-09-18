import { getWindowConfig } from "mirador/dist/es/src/state/selectors";
import { createSelector } from "reselect";

const defaultConfig = {
  // Open the panel
  panelOpen: false,
  // Enable the plugin
  enabled: true,
};

/** Selector to get the plugin config for a given window */
const getPluginConfig = createSelector(
  [getWindowConfig],
  ({ openPanel = {} }) => ({
    ...defaultConfig,
    ...openPanel,
  }),
);

export { getPluginConfig };