import { buildSitesList, buildUser, mockApi, renderApp, screen } from '@/testing/test-utils';
import { beforeEach, describe, expect, it } from 'vitest';
import SitesIndexRoute from '../sites';
import * as SitesIndexRouteModule from '../sites';
import { ROLES } from '@/lib/authorization';

const renderAppAndWait = async () => {
  await renderApp(<SitesIndexRoute />, {
    url: '/admin/sites',
    loaderFn: SitesIndexRouteModule.clientLoader,
  });
};

describe('Sites index route', () => {
  beforeEach(() => {
    mockApi('get', '/sites', { sites: buildSitesList() });
  });
  describe('when user is admin', () => {
    const adminUser = buildUser();

    it('displays the sites dashboard', async () => {
      mockApi('get', '/users/_self', { user: adminUser });
      await renderAppAndWait();

      // expect(screen.getByText(/DLC Subsites Admin Dashboard/i));

      expect(await screen.findByText(/DLC Subsites Admin Dashboard/i));
    });
  });

  describe('when user is editor', () => {
    const editorUser = buildUser({ permissions: { role: ROLES.EDITOR, canEdit: [] } });
    it('displays the sites dashboard', async () => {
      mockApi('get', '/users/_self', { user: editorUser });
      await renderAppAndWait();

      expect(await screen.findByText(/DLC Subsites editor Dashboard/i));
    });
  });

  describe('when user unauthorized', () => {
    const normalUser = buildUser({ permissions: { role: ROLES.USER, canEdit: [] } });
    it('displays auth error', async () => {
      mockApi('get', '/users/_self', { user: normalUser });
      await renderAppAndWait();

      expect(await screen.findByText(/autherror/i));
      expect(await screen.findByText(/only dlc administrators and editors/i));
    });
  });

  // Unauthenticated users are redirected to login, which is handled by Rails
});
