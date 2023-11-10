import { createSelector } from 'reselect';
import { getCurrentCanvas, getManifestLocale } from '@columbia-libraries/mirador/dist/es/src/state/selectors'; 

/** */
function getProperty(property) {
  return createSelector(
    [getCurrentCanvas],
    canvas => canvas && canvas.getProperty(property),
  );
}

/**
* Return the IIIF v2 realated links of canvas or null
* @param {object} state
* @param {object} props
* @param {string} props.manifestId
* @param {string} props.windowId
* @return {String|null}
*/
export const getCanvasRelated = createSelector(
  [
    getProperty('related'),
    getManifestLocale,
  ],
  (relatedLinks, locale) => relatedLinks
    && asArray(relatedLinks).map(related => (
      typeof related === 'string'
        ? {
          value: related,
        }
        : {
          format: related.format,
          label: PropertyValue.parse(related.label, locale)
            .getValue(),
          value: related.id || related['@id'],
        }
    )),
);

/**
* Return the IIIF v3 renderings of a canvas or null
*/
export const getCanvasRenderings = createSelector(
  [getCurrentCanvas],
  canvas => canvas
    && canvas.getRenderings().map(rendering => (
      {
        label: rendering.getLabel().getValue(),
        value: rendering.id,
      }
    )),
);

/**
* Return the IIIF v2/v3 seeAlso data from a canvas or null
*/
export const getCanvasSeeAlso = createSelector(
  [
    getProperty('seeAlso'),
    getManifestLocale,
  ],
  (seeAlso, locale) => seeAlso
    && asArray(seeAlso).map(related => (
      {
        format: related.format,
        label: PropertyValue.parse(related.label, locale)
          .getValue(),
        value: related.id || related['@id'],
      }
    )),
);
