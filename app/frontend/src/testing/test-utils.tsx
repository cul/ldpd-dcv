import React from 'react';
import {
  render as rtlRender,
  screen,
  waitForElementToBeRemoved,
  waitFor,
  within,
  act,
} from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { RouterProvider, createMemoryRouter } from 'react-router';

export {
  buildSite,
  buildSitesList,
  buildUser,
  buildSitePage,
  buildSitePages,
  buildNavGroup,
  buildNavGroups,
  buildNavLink,
  buildNavLinks,
  createTempBannerImage,
  deleteTempBannerImage,
} from './data-generators';
export { mockApi } from './mock-api';

const createTestQueryClient = () =>
  new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        gcTime: Infinity,
      },
    },
  });

/*
  renderApp - renders a component inside a QueryClient + MemoryRouter
*/

interface RenderAppOptions {
  url?: string;
  path?: string;
  [key: string]: unknown;
}

export const renderApp = async (
  ui: React.ReactElement,
  {
    url = '/', // simulated browser location to navigate to (e.g. '/users/janedoe/edit')
    path, // route pattern React Router uses for matching and resolving params (e.g. '/users/:userUid/edit')
    ...renderOptions
  }: RenderAppOptions = {},
) => {
  const queryClient = createTestQueryClient();
  const routePath = path ?? url; // defaults to url — only pass path for parameterized routes
  const isRoot = url === '/';

  const router = createMemoryRouter([{ path: routePath, element: ui }], {
    initialEntries: isRoot ? ['/'] : ['/', url],
    initialIndex: isRoot ? 0 : 1,
  });

  let result;
  await act(async () => {
    result = rtlRender(
      <QueryClientProvider client={queryClient}>
        <RouterProvider router={router} />
      </QueryClientProvider>,
      renderOptions,
    );
  });
  return result;
};

export * from '@testing-library/react';
export { default as userEvent } from '@testing-library/user-event';
export { screen, waitForElementToBeRemoved, waitFor, within };
