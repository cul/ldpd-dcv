

// Returns an anonymous function that closes over the rails route we want
// to navigate to. This can be set directly as the handler for an action
// (like an onClick handler, e.g.: onClick={navigatorToRailsRoute('about')})
//
export const navigatorToRailsRoute = (route: string) => () => {
  window.location.href = route.startsWith('/') ? route : `/${route}`;
}
