import * as React from 'react';
import PropTypes from 'prop-types';
import Badge from '@material-ui/core/Badge';
import CollectionsBookmarkIcon from '@material-ui/icons/CollectionsBookmark';
import LocalePicker from 'mirador/dist/es/src/containers/LocalePicker';
import ManifestInfo from 'mirador/dist/es/src/containers/ManifestInfo';
import CollectionInfo from 'mirador/dist/es/src/containers/CollectionInfo';
import ns from 'mirador/dist/es/src/config/css-ns';

/**
 * WindowSideBarCitationButton
 */
export class WindowSideBarCitationButton extends React.Component {
  /**
   * render
   * @return
   */
  render() {
    const {
      windowId,
      id,
      classes,
      t,
      locale,
      value,
    } = this.props;

    return (
      <Badge overlap="rectangle" classes={{ badge: classes.badge }} variant="dot">
        <CollectionsBookmarkIcon />
      </Badge>
    );
  }
}

/**
TODO: Where are translations registered? Mouseover currently 'openCompanionWindow'
**/

WindowSideBarCitationButton.value = 'citation';

WindowSideBarCitationButton.propTypes = {
  classes: PropTypes.objectOf(PropTypes.string),
  id: PropTypes.string.isRequired,
  locale: PropTypes.string,
  t: PropTypes.func,
  windowId: PropTypes.string.isRequired,
};

WindowSideBarCitationButton.defaultProps = {
  classes: {},
  locale: '',
  t: key => key,
};