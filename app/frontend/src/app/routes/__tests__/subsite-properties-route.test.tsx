import {
  buildNavGroups,
  buildSite,
  buildSitePages,
  buildUser,
  mockApi,
  renderApp,
  screen,
} from '@/testing/test-utils';
import { beforeEach, describe, expect, it } from 'vitest';
import { ROLES } from '@/lib/authorization';
import SubsiteDashboard from '@/features/subsite/components/subsite-dashboard';
import SubsiteProperties from '@/features/subsite/components/subsite-properties';
import SubsiteRoute from '../sites/subsite';
import * as SubsiteRouteModule from '../sites/subsite';

const renderAppAndWait = async () => {
  await renderApp(<SubsiteRoute />, {
    url: '/admin/sites/dlc_subsite/site-properties',
    path: '/admin/sites/:slug',
    loaderFn: SubsiteRouteModule.clientLoader,
    children: [
      { index: true, element: <SubsiteDashboard slug="dlc_subsite" /> },
      { path: 'site-properties', element: <SubsiteProperties slug="dlc_subsite" /> },
    ],
  });
};

describe('Subsite properties route', () => {
  beforeEach(() => {
    mockApi('get', '/sites/dlc_subsite', { site: buildSite() });
    mockApi('get', '/sites/dlc_subsite/pages', { pages: buildSitePages() });
    mockApi('get', '/sites/dlc_subsite/nav_groups', { navGroups: buildNavGroups() });
  });
  describe('when user is admin', () => {
    const adminUser = buildUser();

    it('displays the subsite dashboard', async () => {
      mockApi('get', '/users/_self', { user: adminUser });
      await renderAppAndWait();

      expect(await screen.findByText(/Edit Subsite Properties/i));
    });
  });

  describe('when user is approved editor', () => {
    const editorUser = buildUser({ permissions: { role: ROLES.EDITOR, canEdit: ['dlc_subsite'] } });

    it('displays the subsite dashboard', async () => {
      mockApi('get', '/users/_self', { user: editorUser });
      await renderAppAndWait();

      expect(await screen.findByText(/Edit Subsite Properties/i));
    });
  });

  describe('when user unauthorized', () => {
    const normalUser = buildUser({ permissions: { role: ROLES.USER, canEdit: [] } });

    it('displays auth error', async () => {
      mockApi('get', '/users/_self', { user: normalUser });
      await renderAppAndWait();

      expect(await screen.findByText(/autherror/i));
      expect(await screen.findByText(/you are not authorized to edit/i));
    });
  });

  // Unauthenticated users are redirected to login, which is handled by Rails
});
