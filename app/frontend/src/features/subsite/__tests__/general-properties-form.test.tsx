import { describe, it, expect, beforeEach } from 'vitest';
import {
  mockApi,
  renderApp,
  screen,
  buildSite,
  buildSitePages,
  buildNavGroups,
  userEvent,
  within,
} from '@/testing/test-utils';
import GeneralPropertiesForm from '../components/site-properties/general-properties-form';

const renderAppAndWait = async () => {
  await renderApp(<GeneralPropertiesForm slug="dlc_subsite" />, {
    url: '/admin/sites/dlc_subsite/site-properties',
    path: '/admin/sites/:slug/site-properties',
  });
};

const testSubsite = buildSite();

describe('GeneralPropertiesForm', () => {
  beforeEach(async () => {
    mockApi('get', '/sites/dlc_subsite', { site: testSubsite });
    mockApi('get', '/sites/dlc_subsite/pages', { pages: buildSitePages() });
    mockApi('get', '/sites/dlc_subsite/nav_groups', { navGroups: buildNavGroups() });
    await renderAppAndWait();
  });

  it('contains general properties data for current subsite', async () => {
    const title = await screen.findByLabelText(/^title/i);
    const altTitle = await screen.findByLabelText(/alternative title/i);
    const palette = await screen.findByLabelText(/site palette/i);
    const layout = await screen.findByLabelText(/site layout/i);
    const searchType = await screen.findByLabelText(/search type/i);
    expect(title).toHaveValue(testSubsite.title);
    expect(altTitle).toHaveValue(testSubsite.alternativeTitle);
    expect(palette).toHaveValue(testSubsite.palette);
    expect(layout).toHaveValue(testSubsite.layout);
    expect(searchType).toHaveValue(testSubsite.searchType);
  });

  it('contains a link to facet search config', async () => {
    const link = await screen.findByRole('link', { name: /facet search config/i });
    expect(link).toBeInTheDocument();
  });

  it('has the title input field disabled', async () => {
    const title = await screen.findByLabelText(/^title/i);
    expect(title).toBeDisabled();
  });

  it('shows user unsaved changes message when form is being edited', async () => {
    const altTitle = await screen.findByLabelText(/alternative title/i);
    await userEvent.clear(altTitle);
    await userEvent.type(altTitle, 'new alt title');
    expect(await screen.findByText(/unsaved changes/i)).toBeInTheDocument();
  });

  it('shows success message after submitting form', async () => {
    mockApi('patch', '/sites/dlc_subsite', { site: testSubsite });
    const altTitle = await screen.findByLabelText(/alternative title/i);
    await userEvent.clear(altTitle);
    await userEvent.type(altTitle, 'new alt title');
    const submitButton = await screen.findByRole('button', { name: /save changes/i });
    await userEvent.click(submitButton);
    const message = await screen.findByRole('alert');
    expect(message).toHaveTextContent(/success/i);
  });

  it('shows failure message after submitting form with failure', async () => {
    mockApi('patch', '/sites/dlc_subsite', { site: testSubsite }, 500);
    const altTitle = await screen.findByLabelText(/alternative title/i);
    await userEvent.clear(altTitle);
    await userEvent.type(altTitle, 'new alt title');
    const submitButton = await screen.findByRole('button', { name: /save changes/i });
    await userEvent.click(submitButton);
    const message = await screen.findByRole('alert');
    expect(message).toHaveTextContent(/error/i);
  });

  it('clears unsaved changes message when user makes a change and then undoes it', async () => {
    const altTitle = await screen.findByLabelText(/alternative title/i);
    await userEvent.clear(altTitle);
    await userEvent.type(altTitle, 'new alt title');
    await userEvent.clear(altTitle);
    await userEvent.type(altTitle, testSubsite.alternativeTitle || ''); // the || is needed for typescript to be happy
    expect(screen.queryByText(/unsaved changes/i)).not.toBeInTheDocument();
  });

  it('enables the save button when dirty', async () => {
    const altTitle = await screen.findByLabelText(/alternative title/i);
    await userEvent.clear(altTitle);
    await userEvent.type(altTitle, 'new alt title');
    const submitButton = await screen.findByRole('button', { name: /save changes/i });
    expect(submitButton).toBeEnabled();
  });

  it('disables the save button when not dirty', async () => {
    const submitButton = await screen.findByRole('button', { name: /save changes/i });
    expect(submitButton).toBeDisabled();
  });
});
