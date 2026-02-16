// TODO: add links home

import { useCurrentUser } from "@/lib/authentication";

const NotFoundRoute = () => {
  const { data: user, isLoading } = useCurrentUser();

  if (isLoading) {
    return <div>Loading user account...</div>
  };

  if (!user) {
    return null;
  };

  return (
    <div className="mt-52 flex flex-col items-center font-semibold">
      <h1>404 - Not Found</h1>
      <p>Sorry, the page you are looking for does not exist.</p>
      {user.isAdmin ? <p>Click here to go back to the admin dashboard.</p>}
    </div>
  );
};

export default NotFoundRoute;
