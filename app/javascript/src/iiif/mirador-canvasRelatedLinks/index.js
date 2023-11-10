import CanvasRelatedLinks from "./containers/CanvasRelatedLinks";

import { getPluginConfig } from "@columbia-libraries/mirador/dist/es/src/state/selectors";

export default [
  {
    component: CanvasRelatedLinks,
    mode: "add",
    name: "CanvasRelatedLinks",
    target: "CanvasInfo",
  },
];
