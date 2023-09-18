import * as React from 'react';
import PropTypes from 'prop-types';
import CodeIcon from '@material-ui/icons/Code';
import { MiradorMenuButton } from "mirador/dist/es/src/components/MiradorMenuButton";
import { getManifestoInstance } from 'mirador/dist/es/src/state/selectors/manifests';

self.$RefreshReg$ = () => {};
self.$RefreshSig$ = () => () => {};

const MiradorViewXml = ({ config, containerId, updateConfig }) => {
  const { dialogOpen, enabled } = config;
  if (!enabled) {
    return null;
  }

  return (
    <MiradorMenuButton
      aria-expanded={dialogOpen}
      aria-haspopup
      aria-label="View MODS"
      containerId={containerId}
      onClick={() =>
        updateConfig({
          ...config,
          dialogOpen: !dialogOpen,
        })
      }
    >
          <CodeIcon />
    </MiradorMenuButton>
  );
}

MiradorViewXml.propTypes = {
  config: PropTypes.shape({
    dialogOpen: PropTypes.bool.isRequired,
    enabled: PropTypes.bool.isRequired,
  }).isRequired,
  containerId: PropTypes.string.isRequired,
  updateConfig: PropTypes.func.isRequired,
};

export default MiradorViewXml;