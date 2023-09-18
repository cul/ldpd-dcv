import React, { Component } from 'react';
import PropTypes from 'prop-types';
import { useTheme } from '@material-ui/core/styles';
import Box from "@material-ui/core/Box";
import Button from '@material-ui/core/Button';
import Dialog from '@material-ui/core/Dialog';
import DialogActions from '@material-ui/core/DialogActions';
import DialogTitle from '@material-ui/core/DialogTitle';
import Divider from '@material-ui/core/Divider';
import Link from '@material-ui/core/Link';
import TextField from '@material-ui/core/TextField';
import Typography from '@material-ui/core/Typography';
import XMLViewer from 'react-xml-viewer'
import {fetch as fetchPolyfill} from 'whatwg-fetch'
import ns from "mirador/dist/es/src/config/css-ns";
import ScrollIndicatedDialogContent from 'mirador/dist/es/src/containers/ScrollIndicatedDialogContent';
import { getManifestoInstance } from 'mirador/dist/es/src/state/selectors/manifests';
import { getContainerId } from 'mirador/dist/es/src/state/selectors/config';

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

  const theme = useTheme();
  const closeDialog = () =>
    updateConfig({
      ...config,
      dialogOpen: false,
    });

  return (
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