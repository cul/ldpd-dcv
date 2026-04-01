import { ReactNode, useEffect } from "react";

import { useCurrentUser } from "@/lib/authentication";
import { useLocation } from "react-router-dom";


// Ensures Authentication before serving the app.
// Retrieves the current user data from the query cache, and if not present, redirects to the sign-in page.
const AuthenticationBoundary = ({ children }: { children: ReactNode }) => {
  const { data: user, isLoading } = useCurrentUser(); // subscribe to current user
  const { pathname } = useLocation();

  // If we received a 401 error, or null user data, we must redirect the user to login
  // TODO: because of our long session time (2 weeks) this would be rare, but maybe it is better to handle 401s
  // in the generic api.request function, as other queries could return 401 before this one (so they would show err boundaries).
  useEffect(() => {
    if (!isLoading && !user) {
      window.location.href = `/auth/redirect?return_to=${window.location.origin}/admin${pathname}`;
      return
    };
  }, [user, isLoading, pathname])

  if (isLoading) {
    return <div>Loading user account...</div>
  }

  // TODO : useSuspenseQuery
  if (!user) return null;

  return children;
};

export default AuthenticationBoundary;
