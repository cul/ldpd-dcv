"use strict";

exports.__esModule = true;
exports["default"] = void 0;
var _actions = require("@columbia-libraries/mirador/dist/es/src/state/actions");
var _selectors = require("@columbia-libraries/mirador/dist/es/src/state/selectors");
var _ShareCanvasLinkDialog = _interopRequireDefault(require("./components/ShareCanvasLinkDialog"));
var _ShareControl = _interopRequireDefault(require("./components/ShareControl"));
var _locales = _interopRequireDefault(require("./locales"));
var _selectors2 = require("./state/selectors");
function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }
var _default = [{
  component: _ShareControl["default"],
  config: {
    translations: _locales["default"]
  },
  mapDispatchToProps: function mapDispatchToProps(dispatch, _ref) {
    var windowId = _ref.windowId;
    return {
      updateConfig: function updateConfig(canvasLink) {
        return dispatch((0, _actions.updateWindow)(windowId, {
          canvasLink: canvasLink
        }));
      }
    };
  },
  mapStateToProps: function mapStateToProps(state, _ref2) {
    var windowId = _ref2.windowId;
    return {
      containerId: (0, _selectors.getContainerId)(state),
      config: (0, _selectors2.getPluginConfig)(state, {
        windowId: windowId
      }),
      windowViewType: (0, _selectors.getWindowViewType)(state, {
        windowId: windowId
      })
    };
  },
  mode: "add",
  target: "WindowTopBarPluginArea"
}, {
  component: _ShareCanvasLinkDialog["default"],
  config: {
    translations: _locales["default"]
  },
  mapDispatchToProps: function mapDispatchToProps(dispatch, _ref3) {
    var windowId = _ref3.windowId;
    return {
      updateConfig: function updateConfig(canvasLink) {
        return dispatch((0, _actions.updateWindow)(windowId, {
          canvasLink: canvasLink
        }));
      }
    };
  },
  mapStateToProps: function mapStateToProps(state, _ref4) {
    var windowId = _ref4.windowId;
    return {
      containerId: (0, _selectors.getContainerId)(state),
      manifestId: (0, _selectors.getWindowManifests)(state, {
        windowId: windowId
      })[0],
      visibleCanvases: (0, _selectors.getVisibleCanvases)(state, {
        windowId: windowId
      }),
      config: (0, _selectors2.getPluginConfig)(state, {
        windowId: windowId
      }),
      rights: (0, _selectors.getRights)(state, {
        windowId: windowId
      })
    };
  },
  mode: "add",
  target: "Window"
}];
exports["default"] = _default;
module.exports = exports.default;