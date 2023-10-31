import DownloadIcon from "@mui/icons-material/VerticalAlignBottomSharp";
import { MiradorMenuButton } from "@columbia-libraries/mirador/dist/es/src/components/MiradorMenuButton";
import PropTypes from "prop-types";
import React from "react";

const DownloadButton = ({ config, containerId, t, updateConfig }) => {
  const { dialogOpen, enabled } = config;
  if (!enabled) {
    return null;
  }
  return (
    <MiradorMenuButton
      aria-expanded={dialogOpen}
      aria-haspopup
      aria-label={t("showDownloadOptions")}
      containerId={containerId}
      onClick={() =>
        updateConfig({
          ...config,
          dialogOpen: !dialogOpen,
        })
      }
    >
      <DownloadIcon />
    </MiradorMenuButton>
  );
};

DownloadButton.propTypes = {
  config: PropTypes.shape({
    dialogOpen: PropTypes.bool.isRequired,
    enabled: PropTypes.bool.isRequired,
  }).isRequired,
  containerId: PropTypes.string.isRequired,
  t: PropTypes.func.isRequired,
  updateConfig: PropTypes.func.isRequired,
};

export default DownloadButton;