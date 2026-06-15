import { describe, it, expect, beforeEach } from 'vitest';
import {
  mockApi,
  renderApp,
  screen,
  buildSitePages,
  userEvent,
  within,
} from '@/testing/test-utils';
import SitePagesGeneralForm from '../components/site-properties/site-pages-general-form';

const testPages = buildSitePages();

const renderAppAndWait = async () => {
  await renderApp(<SitePagesGeneralForm slug="dlc_subsite" />, {
    url: '/admin/sites/dlc_subsite/site-properties',
    path: '/admin/sites/:slug/site-properties',
  });
};

describe('SitePagesGeneralForm', () => {
  beforeEach(async () => {
    mockApi('get', '/sites/dlc_subsite/pages', { pages: testPages });
    await renderAppAndWait();
  });

  it('renders the form with initial data', async () => {
    const pageTitles = await screen.findAllByLabelText(/title/i);
    expect(pageTitles[0]).toHaveValue(testPages[0].title);
    expect(pageTitles[1]).toHaveValue(testPages[1].title);
  });

  it('does not have a remove button for home page', async () => {
    // const pageTitles = await screen.findAllByLabelText(/title/i);
    const homePageRow = await screen.findByTestId('page-row-home');
    const removeButton = within(homePageRow).queryByRole('button', { name: /remove/i });
    expect(removeButton).toBeNull();
  });

  it('shows unsaved changes if form is dirty', async () => {
    const pageTitles = await screen.findAllByLabelText(/title/i);
    await userEvent.clear(pageTitles[0]);
    expect(await screen.findByText(/unsaved changes/i)).toBeInTheDocument();
  });

  it('shows no unsaved changes if form is changed then reverted', async () => {
    const pageTitles = await screen.findAllByLabelText(/title/i);
    await userEvent.clear(pageTitles[0]);
    await userEvent.type(pageTitles[0], testPages[0].title);
    expect(screen.queryByText(/unsaved changes/i)).not.toBeInTheDocument();
  });

  it('removes a page when you click a remove button', async () => {
    const row = await screen.findByTestId('page-row-page_2');
    const removeButton = within(row as HTMLElement).getByRole('button', { name: /remove/i });
    await userEvent.click(removeButton);
    expect(row).not.toBeInTheDocument();
  });

  it('shows a success alert when form submission works', async () => {
    mockApi('patch', '/sites/dlc_subsite/pages', { pages: testPages });
    const pageTitles = await screen.findAllByLabelText(/title/i);
    await userEvent.clear(pageTitles[0]);
    await userEvent.type(pageTitles[0], 'change');
    const saveButton = await screen.findByRole('button', { name: /save changes/i });
    await userEvent.click(saveButton);
    const alert = await screen.findByRole('alert');
    expect(alert).toHaveTextContent(/success/i);
  });

  it('allows blank titles', async () => {
    mockApi('patch', '/sites/dlc_subsite/pages', { pages: testPages });
    const pageTitles = await screen.findAllByLabelText(/title/i);
    await userEvent.clear(pageTitles[0]);
    const saveButton = await screen.findByRole('button', { name: /save changes/i });
    await userEvent.click(saveButton);
    const alert = await screen.findByRole('alert');
    expect(alert).toHaveTextContent(/success/i);
  });

  it('shows an error alert when form submission fails', async () => {
    mockApi('patch', '/sites/dlc_subsite/pages', { pages: testPages }, 500);
    const pageTitles = await screen.findAllByLabelText(/title/i);
    await userEvent.clear(pageTitles[0]);
    await userEvent.type(pageTitles[0], 'change');
    const saveButton = await screen.findByRole('button', { name: /save changes/i });
    await userEvent.click(saveButton);
    const alert = await screen.findByRole('alert');
    expect(alert).toHaveTextContent(/error/i);
  });
});
