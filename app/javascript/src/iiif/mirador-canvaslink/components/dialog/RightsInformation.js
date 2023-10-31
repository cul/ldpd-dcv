import Link from "@mui/material/Link";
import { makeStyles } from "@mui/styles";
import Alert from "@mui/material/Alert";
import PropTypes from "prop-types";
import React from "react";

const useStyles = makeStyles((theme) => ({
  root: {
    marginTop: theme.spacing(2),
  },
}));

/** Renders the rights information defined in the used manifest */
const RightsInformation = (props) => {
  const { rights, t } = props;
  const { root } = useStyles();
  if (!rights.length) {
    return null;
  }
  return (
    <Alert className={root} severity="warning">
      <span>{t("canvasLink.noteRights", { count: rights.length })}: </span>
      {rights.length === 1 ? (
        <Link href={rights[0]} rel="noopener" target="_blank">
          {rights[0]}
        </Link>
      ) : (
        <ul>
          {rights.map((link) => (
            <li>
              <Link href={link} rel="noopener" target="_blank">
                {link}
              </Link>
            </li>
          ))}
        </ul>
      )}
    </Alert>
  );
};

RightsInformation.propTypes = {
  rights: PropTypes.arrayOf(PropTypes.string).isRequired,
  t: PropTypes.func.isRequired,
};

export default RightsInformation;