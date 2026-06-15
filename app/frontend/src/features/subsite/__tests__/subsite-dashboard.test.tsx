import { describe, it, expect, beforeEach } from 'vitest';
import { mockApi, renderApp, screen, buildSite } from '@/testing/test-utils';
import SubsiteDashboard from '../components/subsite-dashboard';

const renderAppAndWait = async () => {
  await renderApp(<SubsiteDashboard slug="dlc_subsite" />, {
    url: '/admin/sites/dlc_subsite',
    path: '/admin/sites/:slug',
  });
};

describe.only('SubsiteDashboard', () => {
  beforeEach(async () => {
    mockApi('get', '/sites/dlc_subsite', { site: buildSite() });
    await renderAppAndWait();
  });

  it('renders dashboard header the subsite', async () => {
    const heading = await screen.findByRole('heading', { name: /Subsite Dashboard/i });
    expect(heading).toBeInTheDocument();
  });

  it('Renders site properties card', async () => {
    const card = await screen.findByRole('link', { name: /general properties/i });
    expect(card).toBeInTheDocument();
  });

  it('Renders site pages card', async () => {
    const card = await screen.findByRole('link', { name: /edit the pages/i });
    expect(card).toBeInTheDocument();
  });

  it('Renders site configuration card', async () => {
    const card = await screen.findByRole('link', { name: /configure search/i });
    expect(card).toBeInTheDocument();
  });

  it('Renders site permissions card', async () => {
    const card = await screen.findByRole('link', { name: /configure permissions/i });
    expect(card).toBeInTheDocument();
  });

  it('includes a link to the developer documentation', async () => {
    const link = await screen.findByRole('link', { name: 'DLC Site Editor Documentation' });
    expect(link).toBeInTheDocument();
  });
});
