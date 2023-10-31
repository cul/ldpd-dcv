"use strict";

exports.__esModule = true;
exports.getPluginConfig = void 0;
var _selectors = require("@columbia-libraries/mirador/dist/es/src/state/selectors");
var _reselect = require("reselect");
function _extends() { _extends = Object.assign ? Object.assign.bind() : function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; }; return _extends.apply(this, arguments); }
var defaultConfig = {
  // Open the settings dialog
  dialogOpen: false,
  // Enable share plugin
  enabled: true,
  // Show the rights information defined in the manifest
  showRightsInformation: true,
  // Show only in single canvas view,
  singleCanvasOnly: false
};

/** Selector to get the plugin config for a given window */
var getPluginConfig = (0, _reselect.createSelector)([_selectors.getWindowConfig], function (_ref) {
  var _ref$canvasLink = _ref.canvasLink,
    canvasLink = _ref$canvasLink === void 0 ? {} : _ref$canvasLink;
  return _extends({}, defaultConfig, canvasLink);
});
exports.getPluginConfig = getPluginConfig;