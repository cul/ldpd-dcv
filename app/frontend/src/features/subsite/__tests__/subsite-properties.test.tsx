import { describe, it, expect, beforeEach } from 'vitest';
import {
  mockApi,
  renderApp,
  screen,
  buildSite,
  buildSitePages,
  buildNavGroups,
  userEvent,
} from '@/testing/test-utils';
import SubsiteProperties from '../components/subsite-properties';

const renderAppAndWait = async () => {
  await renderApp(<SubsiteProperties slug="dlc_subsite" />, {
    url: '/admin/sites/dlc_subsite/site-properties',
    path: '/admin/sites/:slug/site-properties',
  });
};

describe('SubsiteProperties', () => {
  beforeEach(async () => {
    mockApi('get', '/sites/dlc_subsite', { site: buildSite() });
    mockApi('get', '/sites/dlc_subsite/pages', { pages: buildSitePages() });
    mockApi('get', '/sites/dlc_subsite/nav_groups', { navGroups: buildNavGroups() });
    await renderAppAndWait();
  });

  it('renders the subsite properties header', async () => {
    const header = await screen.findByRole('heading', { name: /subsite properties/i });
    expect(header).toBeInTheDocument();
  });

  it('includes a link to the developer documentation', async () => {
    const link = await screen.findByRole('link', { name: 'DLC Site Editor Documentation' });
    expect(link).toBeInTheDocument();
  });

  describe('about accordion', () => {
    it('Has the About Site Properties accordion', async () => {
      const accordion = await screen.findByRole('button', { name: /about site properties/i });
      expect(accordion).toBeInTheDocument();
    });

    it('Has the About Site Properties accordion collapsed by default', async () => {
      const accordion = await screen.findByRole('button', { name: /about site properties/i });
      expect(accordion).toHaveAttribute('aria-expanded', 'false');
    });

    it('Expands when clicked', async () => {
      const accordion = await screen.findByRole('button', { name: /about site properties/i });
      await userEvent.click(accordion);
      expect(accordion).toHaveAttribute('aria-expanded', 'true');
    });
  });

  describe('general properties form accordion', () => {
    it('Has the general properties form accordion', async () => {
      const accordion = await screen.findByRole('button', {
        name: /edit site general properties/i,
      });
      expect(accordion).toBeInTheDocument();
    });

    it('Has the form accordion expanded by default', async () => {
      const accordion = await screen.findByRole('button', {
        name: /edit site general properties/i,
      });
      expect(accordion).toHaveAttribute('aria-expanded', 'true');
    });

    it('Collapses when clicked', async () => {
      const accordion = await screen.findByRole('button', {
        name: /edit site general properties/i,
      });
      await userEvent.click(accordion);
      expect(accordion).toHaveAttribute('aria-expanded', 'false');
    });
  });

  describe('edit homepage images form accordion', () => {
    it('Has the form accordion', async () => {
      const accordion = await screen.findByRole('button', {
        name: /edit homepage images/i,
      });
      expect(accordion).toBeInTheDocument();
    });

    it('Has the form accordion expanded by default', async () => {
      const accordion = await screen.findByRole('button', {
        name: /edit homepage images/i,
      });
      expect(accordion).toHaveAttribute('aria-expanded', 'true');
    });

    it('Collapses when clicked', async () => {
      const accordion = await screen.findByRole('button', {
        name: /edit homepage images/i,
      });
      await userEvent.click(accordion);
      expect(accordion).toHaveAttribute('aria-expanded', 'false');
    });
  });

  describe('manage site pages form accordion', () => {
    it('Has the form accordion', async () => {
      const accordion = await screen.findByRole('button', {
        name: /manage site pages/i,
      });
      expect(accordion).toBeInTheDocument();
    });

    it('Has the form accordion expanded by default', async () => {
      const accordion = await screen.findByRole('button', {
        name: /manage site pages/i,
      });
      expect(accordion).toHaveAttribute('aria-expanded', 'true');
    });

    it('Collapses when clicked', async () => {
      const accordion = await screen.findByRole('button', {
        name: /manage site pages/i,
      });
      await userEvent.click(accordion);
      expect(accordion).toHaveAttribute('aria-expanded', 'false');
    });
  });

  describe('edit navigation bar form accordion', () => {
    it('Has the form accordion', async () => {
      const accordion = await screen.findByRole('button', {
        name: /edit navigation bar/i,
      });
      expect(accordion).toBeInTheDocument();
    });

    it('Has the form accordion expanded by default', async () => {
      const accordion = await screen.findByRole('button', {
        name: /edit navigation bar/i,
      });
      expect(accordion).toHaveAttribute('aria-expanded', 'true');
    });

    it('Collapses when clicked', async () => {
      const accordion = await screen.findByRole('button', {
        name: /edit navigation bar/i,
      });
      await userEvent.click(accordion);
      expect(accordion).toHaveAttribute('aria-expanded', 'false');
    });
  });
});
