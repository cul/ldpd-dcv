import { getWindowConfig, getManifestLocale, getManifestoInstance } from "mirador/dist/es/src/state/selectors";
import asArray from 'mirador/dist/es/src/lib/asArray';
import { PropertyValue, Utils, Resource } from 'manifesto.js';
import { createSelector } from "reselect";

const defaultConfig = {
  // Open the view dialog
  dialogOpen: false,
  // Enable the plugin
  enabled: true,
};

/** Selector to get the plugin config for a given window */
const getPluginConfig = createSelector(
  [getWindowConfig],
  ({ viewXmlDialog = {} }) => ({
    ...defaultConfig,
    ...viewXmlDialog,
  }),
);

/** copied from Mirador because it is not exported */
const getProperty = (property) => {
  return createSelector(
    [getManifestoInstance],
    manifest => manifest && manifest.getProperty(property),
  );
}

/** modified from Mirador to destructure all the properties */
const getManifestSeeAlso = createSelector(
  [
    getProperty('seeAlso'),
    getManifestLocale,
  ],
  (seeAlso, locale) => seeAlso
    && asArray(seeAlso).map(related => (
      {
        ...related,
        format: related.format,
        label: PropertyValue.parse(related.label, locale)
          .getValue(),
        value: related.id || related['@id'],
      }
    )),
);
export { getManifestSeeAlso, getPluginConfig };