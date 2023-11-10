import { compose } from 'redux';
import { connect } from 'react-redux';
import { withTranslation } from 'react-i18next';
import { withPlugins } from '@columbia-libraries/mirador/dist/es/src/extend/withPlugins';
import {
  getCanvasRelated,
  getCanvasRenderings,
  getCanvasSeeAlso,
} from '../state/selectors';
import { CanvasRelatedLinks } from '../components/CanvasRelatedLinks';


/**
 * mapStateToProps - to hook up connect
 * @memberof CanvasInfo
 * @private
 */
const mapStateToProps = (state, { id, windowId }) => ({
  related: getCanvasRelated(state, { windowId }),
  renderings: getCanvasRenderings(state, { windowId }),
  seeAlso: getCanvasSeeAlso(state, { windowId }),
});

const enhance = compose(
  withTranslation(),
  connect(mapStateToProps),
  withPlugins('CanvasRelatedLinks'),
);

export default enhance(CanvasRelatedLinks);
