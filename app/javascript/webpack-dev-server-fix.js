// This fixes a "$RefreshReg$ is not defined" error that comes up when running the webpack dev server.
// See: https://github.com/pmmmwh/react-refresh-webpack-plugin/issues/176
window.$RefreshReg$ = () => { };
window.$RefreshSig$ = () => () => { };
