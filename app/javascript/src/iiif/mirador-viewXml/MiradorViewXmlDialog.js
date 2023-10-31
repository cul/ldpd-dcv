import React, { Component } from 'react';
import { createTheme, ThemeProvider } from '@mui/material';
import PropTypes from 'prop-types';
import Box from "@mui/material/Box";
import Button from '@mui/material/Button';
import Dialog from '@mui/material/Dialog';
import DialogActions from '@mui/material/DialogActions';
import DialogTitle from '@mui/material/DialogTitle';
import Divider from '@mui/material/Divider';
import Link from '@mui/material/Link';
import TextField from '@mui/material/TextField';
import Typography from '@mui/material/Typography';
import XMLViewer from 'react-xml-viewer'
import {fetch as fetchPolyfill} from 'whatwg-fetch'
import ns from "@columbia-libraries/mirador/dist/es/src/config/css-ns";
import ScrollIndicatedDialogContent from '@columbia-libraries/mirador/dist/es/src/containers/ScrollIndicatedDialogContent';
import { getManifestoInstance } from '@columbia-libraries/mirador/dist/es/src/state/selectors/manifests';
import { getContainerId } from '@columbia-libraries/mirador/dist/es/src/state/selectors/config';

self.$RefreshReg$ = () => {};
self.$RefreshSig$ = () => () => {};

/**
 * MiradorViewXmlDialog ~
*/
const MiradorViewXmlDialog = ({
  config,
  containerId,
  manifestId,
  seeAlso,
  updateConfig,
  windowId,
}) => {
  const { dialogOpen, enabled, xmlSource } = config;
  if (!enabled || !dialogOpen) {
    return null;
  }

  const xmlLink = function(relateds) {
    if (!relateds) return null;
    return relateds.find(ref => ref.schema == 'http://www.loc.gov/mods/v3')?.id;
  }(seeAlso);

  if (!xmlLink) return null;

  if (!config.xmlSource) {
    fetchPolyfill(xmlLink).then(function(response) {
      return response.text()
    }).then(function(body) {
      updateConfig(
      {
        ...config,
        xmlSource: body,
      }
      )
    })
  }

  const closeDialog = () =>
    updateConfig({
      ...config,
      dialogOpen: false,
    });

  const theme = createTheme();

  return (
    <ThemeProvider theme={theme}>
    <Dialog
      container={document.querySelector(`#${containerId} .${ns("viewer")}`)}
      fullWidth
      maxWidth="xl"
      onClose={closeDialog}
      open={dialogOpen}
      scroll="paper"
    >
      <DialogTitle disableTypography>
        <Typography variant="h4">
          <Box fontWeight="fontWeightBold">MODS XML</Box>
        </Typography>
      </DialogTitle>
      <ScrollIndicatedDialogContent>
        <XMLViewer xml={xmlSource} />
      </ScrollIndicatedDialogContent>
      <DialogActions>
        <Button color="primary" onClick={closeDialog}>
          Close
        </Button>
      </DialogActions>
    </Dialog>
    </ThemeProvider>
  );
}

MiradorViewXmlDialog.propTypes = {
  config: PropTypes.shape({
    dialogOpen: PropTypes.bool.isRequired,
    enabled: PropTypes.bool.isRequired,
    xmlSource: PropTypes.string,
  }).isRequired,
  containerId: PropTypes.string.isRequired,
  manifestId: PropTypes.string,
  seeAlso: PropTypes.arrayOf(
    PropTypes.shape({
      format: PropTypes.string,
      label: PropTypes.string,
      value: PropTypes.string,
      schema: PropTypes.string,
      profile: PropTypes.string,
    }),
  ),
  updateConfig: PropTypes.func.isRequired,
  windowId: PropTypes.string.isRequired,
};

MiradorViewXmlDialog.defaultProps = {
  manifestId: '',
  seeAlso: [],
};

export default MiradorViewXmlDialog;