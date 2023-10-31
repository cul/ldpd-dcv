import InputAdornment from "@mui/material/InputAdornment";
import FileCopyIcon from "@mui/icons-material/FileCopy";
import { MiradorMenuButton } from "@columbia-libraries/mirador/dist/es/src/components/MiradorMenuButton";
import PropTypes from "prop-types";
import React from "react";

const CopyToClipboard = (props) => {
  const { onCopy, supported, t } = props;
  if (!supported) {
    return null;
  }
  return (
    <InputAdornment>
      <MiradorMenuButton
        aria-label={t("canvasLink.copyToClipboard")}
        edge="end"
        onClick={onCopy}
      >
        <FileCopyIcon fontSize="small" />
      </MiradorMenuButton>
    </InputAdornment>
  );
}

CopyToClipboard.propTypes = {
  onCopy: PropTypes.func.isRequired,
  supported: PropTypes.bool.isRequired,
  t: PropTypes.func.isRequired,
};

export default CopyToClipboard;