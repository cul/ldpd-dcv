import { describe, it, expect, beforeEach } from 'vitest';
import { buildSitesList, buildUser, mockApi, renderApp, within, screen, act } from '@/testing/test-utils';
import SitesDashboard from '@/features/sites/components/sites-dashboard';
import { ROLES } from '@/lib/authorization';

describe('SitesDashboard', () => {
  beforeEach(() => {
    mockApi('get', '/sites', { sites: buildSitesList(3)});
  });

  describe('as an admin user', () => {
    beforeEach(async () => {
      mockApi('get', '/users/_self', { user: buildUser() });
      await renderApp(<SitesDashboard />,{url: '/admin/sites'});
    })
  
    it('renders a list of sites with admin text', async () => {
      const heading = await screen.findByRole('heading', { name: 'DLC Subsites Admin Dashboard' });
      expect(heading).toBeInTheDocument();
    });

    it('renders correct list of column headers', async () => {
      const table = await screen.findByRole('table', { name: 'Your DLC Subsites' });
      const rows = within(table).getAllByRole('row');
      const headers = within(rows[0]).getAllByRole('columnheader')
      expect(headers[0]).toHaveTextContent('Site Name');
      expect(headers[1]).toHaveTextContent('Site Slug');
      expect(headers[2]).toHaveTextContent('Link to Subsite Dashboard');
    });

    it('renders a row for each subsite', async () => {
      const table = await screen.findByRole('table', { name: 'Your DLC Subsites' });
      const rows = within(table).getAllByRole('row');
      expect(rows).toHaveLength(4);
    });

    it('includes a link to the developer documentation', async () => {
      const link = await screen.findByRole('link', { name: 'DLC Site Editor Documentation' })
      expect(link).toBeInTheDocument();
    });
  });

  describe('as an editor user', () => {
    beforeEach(async () => {
      const editorUser = buildUser({ permissions: {role: ROLES.EDITOR, canEdit: ['dlc_subsite_1']} });
      mockApi('get', '/users/_self', { user: editorUser });
      await renderApp(<SitesDashboard />,{url: '/admin/sites'});
    })

    it('renders a list of sites with editor text', async () => {
      const heading = await screen.findByRole('heading', { name: 'DLC Subsites Editor Dashboard' });
      expect(heading).toBeInTheDocument();
    });
  });
});