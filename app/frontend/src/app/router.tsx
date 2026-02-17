import { useMemo } from 'react';
import { QueryClient, useQueryClient } from '@tanstack/react-query';
import { LoaderFunction, ActionFunction, createBrowserRouter, Link } from 'react-router-dom';
import { RouterProvider } from 'react-router-dom';
import MainLayout from "@/components/layouts/main-layout/main-layout";
import SitesRoute from './routes/sites';


function Root() {
  return (
    // TODO: protected route for admin users only ---> actually, no auth is needed in this app at all, because rails will check for auth before rendering the admin view where we mount the app!
    <div>
      <h1>Admin React App</h1>
      <p>Welcome to the admin dashboard!</p>
      <p>The only admin feature available is the sites admin dashboard.
        <Link to="/sites">Click here to view it!</Link>
      </p>
    </div>
  );
}

interface RouteModule {
  default: React.ComponentType;
  clientLoader?: (queryClient: QueryClient) => LoaderFunction;
  clientAction?: (queryClient: QueryClient) => ActionFunction;
  [key: string]: unknown; // todo: why?
}

// Convert a module with clientLoader/clientAction into a route object.
// This allows loaders/actions to access the QueryClient for prefetching data.
// As a result, route modules must export the following:
// - default: the component to render for the route (index, edit, etc.)
// - clientLoader: a function that takes a QueryClient and returns a loader function (optional - only needed if the route needs to load data)
// - clientAction: a function that takes a QueryClient and returns an action function (optional - only needed if the route needs to handle form submissions or other actions)
const convert = (queryClient: QueryClient) => (m: RouteModule) => {
  const { clientLoader, clientAction, default: Component, ...rest } = m;
  return {
    ...rest,
    loader: clientLoader?.(queryClient),
    action: clientAction?.(queryClient),
    Component,
  };
};

const createAppRouter = (queryClient: QueryClient) => {
  // all routes begin with /admin/ --- we are matching on the rest
  return createBrowserRouter([
    {
      Component: MainLayout,
      children: [
        {
          // admin/ -> admin 'dashboard'
          // Only for admin
          index: true,
          Component: Root,
        },
        {
          path: 'sites',
          // Component: SitesRoute,
          children: [
            {
              // admin/sites -> sites admin dashboard
              // Only for admin
              index: true,
              lazy: () => import('./routes/sites').then(convert(queryClient)),
            },
            {
              path: ':slug',
              lazy: () => import('./routes/sites/edit').then(convert(queryClient)),
            }
          ]
        }
      ],
    },
    {
      path: '*',
      lazy: () => import('./routes/not-found').then(m => ({ Component: m.default })),
    }
  ], {
    basename: '/admin',
  });
};

const AppRouter = () => {
  const queryClient = useQueryClient();

  const router = useMemo(() => createAppRouter(queryClient), [queryClient]);

  return (
    <RouterProvider router={router} />
  );
};

export { AppRouter };