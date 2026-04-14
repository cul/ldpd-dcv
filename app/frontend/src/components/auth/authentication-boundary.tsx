import { ReactNode, useEffect } from "react";
import { useLocation } from "react-router";

import { useCurrentUser } from "@/lib/authentication";


// Ensures Authentication before rendering the app.
// Retrieves the current user data from the query cache, ensures we are always subscribed to
// the current user, and if not present, redirects to the sign-in page.
const AuthenticationBoundary = ({ children }: { children: ReactNode }) => {
  const { data: user, isLoading } = useCurrentUser(); // subscribe to current user
  const { pathname } = useLocation();

  // If we received a 403 error, or null user data, we must redirect the user to login
  // This should be caught in the api-client code, but in case the user data is every null,
  // we would want to consider it an expired session and redirect to login.
  useEffect(() => {
    if (!isLoading && !user) {
      const returnTo = `${window.location.href}`
      window.location.replace(`/auth/redirect?return_to=${returnTo}`);
      return
    };
  }, [user, isLoading, pathname])

  if (isLoading) {
    return <div>Loading user account...</div>
  }

  // Should be caught in useEffect!
  if (!user) return null;

  return children;
};

export default AuthenticationBoundary;
