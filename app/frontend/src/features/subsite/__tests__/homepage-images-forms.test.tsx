import { describe, it, expect, beforeEach, afterAll, beforeAll, vi } from 'vitest';
import {
  mockApi,
  renderApp,
  screen,
  buildSite,
  buildSitePages,
  buildNavGroups,
  userEvent,
  within,
  createTempBannerImage,
  deleteTempBannerImage,
} from '@/testing/test-utils';
import { SiteLayout } from '@/types/api';
import HomepageImagesForms from '../components/site-properties/homepage-images-forms';

const renderAppAndWait = async () => {
  await renderApp(<HomepageImagesForms slug="dlc_subsite" />, {
    url: '/admin/sites/dlc_subsite/site-properties',
    path: '/admin/sites/:slug/site-properties',
  });
};

const testSubsiteSignature = buildSite(); // Default test layout is Signature
const testSubsitePortrait = buildSite({ layout: SiteLayout.PORTRAIT });
const testSubsiteRepositories = buildSite({ layout: SiteLayout.REPOSITORIES });

describe('HomepageImagesForm', () => {
  beforeEach(async () => {
    mockApi('get', '/sites/dlc_subsite/pages', { pages: buildSitePages() });
    mockApi('get', '/sites/dlc_subsite/nav_groups', { navGroups: buildNavGroups() });
  });

  ///////////////// PORTRAIT LAYOUT IMAGE FORM ////////////////
  describe('PortraitLayoutImageForm', async () => {
    beforeEach(async () => {
      mockApi('get', '/sites/dlc_subsite', { site: testSubsitePortrait });
      await renderAppAndWait();
    });

    it('has the proper fetched initial data', async () => {
      const pidInputs = await screen.findAllByLabelText(/pid/i);
      expect(pidInputs).toHaveLength(2);
      expect(pidInputs[0]).toHaveValue(testSubsitePortrait.imageUris[0]);
      expect(pidInputs[1]).toHaveValue(testSubsitePortrait.imageUris[1]);
    });

    it('adds a new input when you click add button', async () => {
      const button = await screen.findByRole('button', { name: /add/i });
      await userEvent.click(button);
      const pidInputs = await screen.findAllByLabelText(/pid/i);
      expect(pidInputs).toHaveLength(3);
    });

    it('has a remove button for each input', async () => {
      const buttons = await screen.findAllByRole('button', { name: /remove/i });
      expect(buttons).toHaveLength(2);
    });

    it('removes a pid when you click remove button', async () => {
      const button = (await screen.findAllByRole('button', { name: /remove/i }))[0];
      await userEvent.click(button);
      const pidInputs = await screen.findAllByLabelText(/pid/i);
      expect(pidInputs).toHaveLength(1);
    });

    it('has remove button disabled when only one pid in form', async () => {
      const buttons = await screen.findAllByRole('button', { name: /remove/i });
      const button1 = buttons[0];
      const button2 = buttons[1];
      await userEvent.click(button1);
      const pidInputs = await screen.findAllByLabelText(/pid/i);
      expect(pidInputs).toHaveLength(1);
      expect(button2).toBeDisabled();
    });

    it('shows validation error when pid is empty', async () => {
      const portraitForm = await screen.findByRole('form', { name: /portrait layout images/i });
      const pid1 = (await screen.findAllByLabelText(/pid/i))[0];
      await userEvent.clear(pid1);
      await userEvent.click(portraitForm);
      const validationError = await screen.findByText(/cannot be blank/i);
      expect(validationError).toBeInTheDocument();
    });

    it('enables the save button when dirty', async () => {
      const pid1 = (await screen.findAllByLabelText(/pid/i))[0];
      await userEvent.clear(pid1);
      await userEvent.type(pid1, 'change');
      const portraitForm = await screen.findByRole('form', { name: /portrait layout images/i });
      const saveButton = within(portraitForm).getByRole('button', { name: /save/i });
      expect(saveButton).toBeEnabled();
    });

    it('disables the save button when not dirty', async () => {
      const portraitForm = await screen.findByRole('form', { name: /portrait layout images/i });
      const saveButton = within(portraitForm).getByRole('button', { name: /save/i });
      expect(saveButton).toBeDisabled();
    });

    it('shows user unsaved changes message when form is being edited', async () => {
      const pid1 = (await screen.findAllByLabelText(/pid/i))[0];
      await userEvent.clear(pid1);
      await userEvent.type(pid1, 'change');
      expect(await screen.findByText(/unsaved changes/i)).toBeInTheDocument();
    });

    it('shows success message after submitting form', async () => {
      mockApi('patch', '/sites/dlc_subsite', { site: testSubsitePortrait });
      const pid1 = (await screen.findAllByLabelText(/pid/i))[0];
      await userEvent.clear(pid1);
      await userEvent.type(pid1, 'change');
      const portraitForm = await screen.findByRole('form', { name: /portrait layout images/i });
      const saveButton = within(portraitForm).getByRole('button', { name: /save/i });
      await userEvent.click(saveButton);
      const alert = await screen.findByRole('alert');
      expect(alert).toHaveTextContent(/success/i);
    });

    it('shows failure message after submitting form with failure', async () => {
      mockApi('patch', '/sites/dlc_subsite', { site: testSubsitePortrait }, 500);
      const pid1 = (await screen.findAllByLabelText(/pid/i))[0];
      await userEvent.clear(pid1);
      await userEvent.type(pid1, 'change');
      const portraitForm = await screen.findByRole('form', { name: /portrait layout images/i });
      const saveButton = within(portraitForm).getByRole('button', { name: /save/i });
      await userEvent.click(saveButton);
      const alert = await screen.findByRole('alert');
      expect(alert).toHaveTextContent(/error/i);
    });

    it('clears unsaved changes message when user makes a change and then undoes it', async () => {
      const pid1 = (await screen.findAllByLabelText(/pid/i))[0];
      await userEvent.clear(pid1);
      await userEvent.type(pid1, testSubsitePortrait.imageUris[0]);
      expect(screen.queryByText(/unsaved changes/i)).not.toBeInTheDocument();
    });

    it('has portrait images sub-form accordion expanded by default', async () => {
      const portraitLayoutForm = await screen.findByRole('button', {
        name: /portrait layout images/i,
      });
      expect(portraitLayoutForm).toHaveAttribute('aria-expanded', 'true');
    });

    it('clicking the sub-form accordion heading collapses it', async () => {
      const portraitLayoutForm = await screen.findByRole('button', {
        name: /portrait layout images/i,
      });
      expect(portraitLayoutForm).toHaveAttribute('aria-expanded', 'true');
      await userEvent.click(portraitLayoutForm);
      expect(portraitLayoutForm).toHaveAttribute('aria-expanded', 'false');
    });
  });

  ////////////////  SIGNATURE IMAGES //////////////////
  describe('SignatureLayoutImageForm', async () => {
    beforeAll(() => {
      createTempBannerImage();
    });

    afterAll(() => {
      deleteTempBannerImage();
    });

    beforeEach(async () => {
      mockApi('get', '/sites/dlc_subsite', { site: testSubsiteSignature });
      await renderAppAndWait();
    });

    it('has portrait images sub-form accordion expanded by default', async () => {
      const signatureLayoutForm = await screen.findByRole('button', {
        name: /signature layout images/i,
      });
      expect(signatureLayoutForm).toHaveAttribute('aria-expanded', 'true');
    });

    it('clicking the sub-form accordion heading collapses it', async () => {
      const signatureLayoutForm = await screen.findByRole('button', {
        name: /signature layout images/i,
      });
      expect(signatureLayoutForm).toHaveAttribute('aria-expanded', 'true');
      await userEvent.click(signatureLayoutForm);
      expect(signatureLayoutForm).toHaveAttribute('aria-expanded', 'false');
    });

    it('displays the current banner and signature images', async () => {
      const bannerImage = await screen.findByAltText(/banner image/i);
      const watermarkImage = await screen.findByAltText(/watermark image/i);
      expect(bannerImage).toBeInTheDocument();
      expect(watermarkImage).toBeInTheDocument();
    });

    it('has download link for an uploaded image', async () => {
      const bannerImage = await screen.findByAltText(/banner image/i);
      const parent = bannerImage.parentElement;
      expect(parent?.tagName).toBe('A');
      expect(parent).toHaveAttribute('href', testSubsiteSignature.bannerImageUrl);
    });

    it('displays a delete button for an uploaded image', async () => {
      const deleteButton = await screen.findByRole('button', { name: /delete banner image/i });
      expect(deleteButton).toBeInTheDocument();
    });

    it('asks before allowing deletion', async () => {
      const confirmSpy = vi.spyOn(window, 'confirm').mockReturnValue(false);
      const deleteButton = await screen.findByRole('button', { name: /delete banner image/i });
      await userEvent.click(deleteButton);
      expect(confirmSpy).toHaveBeenCalled();
    });

    it('does not display a delete button for a default image', async () => {
      expect(screen.queryByText(/delete watermark image/i)).not.toBeInTheDocument();
    });

    it('shows success message after submitting form', async () => {
      mockApi('patch', '/sites/dlc_subsite/signature_images', { site: testSubsiteSignature });
      const signatureForm = await screen.findByRole('form', { name: /signature layout images/i });
      const saveButton = within(signatureForm).getByRole('button', { name: /save/i });
      const watermarkInput = within(signatureForm).getByLabelText(/watermark image/i);
      const file = new File(['file'], 'file.svg', { type: 'image/svg' });
      await userEvent.upload(watermarkInput, file);
      userEvent.click(saveButton);
      const alert = await screen.findByRole('alert');
      expect(alert).toHaveTextContent(/Your image has been uploaded and saved/i);
    });

    it('shows error message after submission results in error', async () => {
      mockApi('patch', '/sites/dlc_subsite/signature_images', { site: testSubsiteSignature }, 500);
      const signatureForm = await screen.findByRole('form', { name: /signature layout images/i });
      const saveButton = within(signatureForm).getByRole('button', { name: /save/i });
      userEvent.click(saveButton);
      const alert = await screen.findByRole('alert');
      expect(alert).toHaveTextContent(/error/i);
    });

    it('shows success message after deleting image', async () => {
      mockApi(
        'delete',
        '/sites/dlc_subsite/signature_images/banner',
        { site: testSubsiteSignature },
        200,
      );
      const confirmSpy = vi.spyOn(window, 'confirm').mockReturnValue(true);
      const deleteButton = await screen.findByRole('button', { name: /delete banner image/i });
      await userEvent.click(deleteButton);
      expect(confirmSpy).toHaveBeenCalled();
      const alert = await screen.findByRole('alert');
      expect(alert).toHaveTextContent(/Your banner image has been deleted/i);
    });

    it('shows error message after deleting image with error', async () => {
      mockApi(
        'delete',
        '/sites/dlc_subsite/signature_images/banner',
        { site: testSubsiteSignature },
        500,
      );
      const confirmSpy = vi.spyOn(window, 'confirm').mockReturnValue(true);
      const deleteButton = await screen.findByRole('button', { name: /delete banner image/i });
      await userEvent.click(deleteButton);
      expect(confirmSpy).toHaveBeenCalled();
      const alert = await screen.findByRole('alert');
      expect(alert).toHaveTextContent(/error/i);
    });

    it('shows a validation error message when file upload wrong type', async () => {
      mockApi('patch', '/sites/dlc_subsite/signature_images', { site: testSubsiteSignature });
      const signatureForm = await screen.findByRole('form', { name: /signature layout images/i });
      const saveButton = within(signatureForm).getByRole('button', { name: /save/i });
      const watermarkInput = within(signatureForm).getByLabelText(/watermark image/i);
      const file = new File(['file'], 'file.png', { type: 'image/png' });
      await userEvent.upload(watermarkInput, file);
      userEvent.click(saveButton);
      const validationError = await screen.findByText(/only svg/i);
      expect(validationError).toBeInTheDocument();
    });
  });

  describe('with neither signature nor portrait layout', async () => {
    beforeEach(async () => {
      mockApi('get', '/sites/dlc_subsite', { site: testSubsiteRepositories });
      await renderAppAndWait();
    });
    it('has neither sub-form expanded by default', async () => {
      const portraitLayoutForm = await screen.findByRole('button', {
        name: /portrait layout images/i,
      });
      const signatureLayoutForm = await screen.findByRole('button', {
        name: /signature layout images/i,
      });
      expect(portraitLayoutForm).toHaveAttribute('aria-expanded', 'false');
      expect(signatureLayoutForm).toHaveAttribute('aria-expanded', 'false');
    });
  });
});
