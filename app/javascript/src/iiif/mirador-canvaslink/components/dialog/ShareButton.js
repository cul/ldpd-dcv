import FacebookIcon from "@mui/icons-material/Facebook";
import MailIcon from "@mui/icons-material/Mail";
import PinterestIcon from "@mui/icons-material/Pinterest";
import TwitterIcon from "@mui/icons-material/Twitter";
import WhatsAppIcon from "@mui/icons-material/WhatsApp";
import { MiradorMenuButton } from "@columbia-libraries/mirador/dist/es/src/components/MiradorMenuButton";
import PropTypes from "prop-types";
import React from "react";

import { getShareLink } from "../utils";


const iconMapping = {
  envelope: MailIcon,
  facebook: FacebookIcon,
  pinterest: PinterestIcon,
  twitter: TwitterIcon,
  whatsapp: WhatsAppIcon,
};

/** Renders a button for sharing the given content on one of the supported providers */
const ShareButton = (props) => {
  const {
    attribution,
    canvasLink,
    label,
    provider,
    thumbnailUrl,
    title,
  } = props;
  const link = getShareLink(
    attribution,
    canvasLink,
    label,
    provider,
    thumbnailUrl,
  );
  const ProviderIcon = iconMapping[provider];
  return (
    <MiradorMenuButton
      aria-label={title}
      href={encodeURI(link)}
      rel="noopener"
      target="_blank"
    >
      <ProviderIcon />
    </MiradorMenuButton>
  );
};

ShareButton.defaultProps = {
  attribution: undefined,
};

ShareButton.propTypes = {
  attribution: PropTypes.string,
  canvasLink: PropTypes.string.isRequired,
  label: PropTypes.string.isRequired,
  provider: PropTypes.string.isRequired,
  thumbnailUrl: PropTypes.string.isRequired,
  title: PropTypes.string.isRequired,
};

export default ShareButton;