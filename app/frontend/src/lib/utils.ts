// Returns an anonymous function that closes over the rails route we want
// to navigate to. This can be set directly as the handler for an action
// (like an onClick handler, e.g.: onClick={navigatorToRailsRoute('about')})
export const navigatorToRailsRoute = (route: string) => () => {
  window.location.href = route.startsWith('/') ? route : `/${route}`;
}

export const formatDate = (dateString: string): string => {
  return new Intl.DateTimeFormat('en-US', {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(dateString));
}

export const formatDateRelative = (dateString: string): string => {
  const seconds = Math.floor((Date.now() - new Date(dateString).getTime()) / 1000);
  const rtf = new Intl.RelativeTimeFormat('en', { numeric: 'auto' });

  if (seconds < 60) return rtf.format(-seconds, 'second');
  if (seconds < 3600) return rtf.format(-Math.floor(seconds / 60), 'minute');
  if (seconds < 86400) return rtf.format(-Math.floor(seconds / 3600), 'hour');
  return rtf.format(-Math.floor(seconds / 86400), 'day');
};