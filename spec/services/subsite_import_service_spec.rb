# frozen_string_literal: true

require 'rails_helper'

# N.B. These tests use fixture data that are zip files located in spec/fixtures/import_service/
# If certain constants (like the name of metadata files) change, than this data will
# no longer work for these tests. If that happens, make sure to update the fixture
# data appropriately.
# The fixture data zip files are created from the factory data for the following models:
#   - sites
#   - site_pages
#   - text_blocks
#   - nav_links
# And were created by running the export service spec and saving the output zip file.
# See the factory files (in spec/factories) and export service spec for more details on
# the data that is included in the fixture zip files.
RSpec.describe SubsiteImportService do
  let(:fixture_path) { File.join(Rails.root, 'spec', 'fixtures', 'import_service') }

  describe '#import_subsite' do
    context 'when non-admin' do
      let(:test_import_path) { File.join(fixture_path, 'test_import.zip') }
      let(:import) { SubsiteImportService.new(test_import_path, false) }

      it 'does not allow import of a new subsite' do
        expect { import.import_subsite }.to raise_error(Exceptions::SubsiteUploadError)
      end
      it 'does allow import of an existing subsite' do
        FactoryBot.create(:site, slug: 'dlc_site', title: 'Existing DLC Site')
        expect { import.import_subsite }.not_to raise_error
      end
    end

    context 'with a valid import' do
      let(:test_import_path) { File.join(fixture_path, 'test_import.zip') }
      let(:import) { SubsiteImportService.new(test_import_path, true) }

      context 'when importing a subsite' do
        before do
          import.import_subsite
        end

        it 'saves the subsite to the database' do
          expect(Site.find_by(slug: 'dlc_site')).not_to be_nil
        end
        it 'saves any pages to the database' do
          expect(SitePage.find_by(slug: 'home', site_id: Site.find_by(slug: 'dlc_site').id)).not_to be_nil
        end
        it 'saves any text blocks to the database' do
          site_page = SitePage.find_by(slug: 'home', site_id: Site.find_by(slug: 'dlc_site').id)
          expect(SiteTextBlock.find_by(sort_label: '00:Text Block', site_page_id: site_page.id)).not_to be_nil
        end
        it 'saves any nav links to the database' do
          site = Site.find_by(slug: 'dlc_site')
          nav_links = site.nav_links
          expect(nav_links.length).to eql(3)
        end

        context 'when importing a new subsite' do
          it 'has a created new success message' do
            expect(import.finish_message).to include('Created')
          end
        end
      end

      context 'when importing an existing subsite' do
        let(:original_uids) { ['1','2','3','4'] }

        before do
          existing_site = FactoryBot.create(:site, slug: 'dlc_site', title: 'Existing DLC Site', editor_uids: original_uids)
          existing_site.site_pages << FactoryBot.create(:site_page, slug: 'existing_page', site: existing_site)
          import.import_subsite
        end

        it 'does not create a new subsite' do
          expect(Site.where(slug: 'dlc_site').count).to eql(1)
        end
        it 'overwrites the existing subsite data with the imported data' do
          expect(Site.find_by(slug: 'dlc_site').title).to eql('DLC Site')
        end
        it 'removes any existing pages that are not included in the import' do
          expect(SitePage.find_by(slug: 'existing_page', site_id: Site.find_by(slug: 'dlc_site').id)).to be_nil
        end
        it 'saves any new pages included in the import' do
          expect(SitePage.find_by(slug: 'home', site_id: Site.find_by(slug: 'dlc_site').id)).not_to be_nil
        end
        it 'has an updated success message' do
          expect(import.finish_message).to include('Updated')
        end
        it 'does not overwrite the editor list' do
          expect(Site.find_by(slug: 'dlc_site').editor_uids).to eq(original_uids)
        end
      end

      context 'when an unknown error occurs' do
        before do
          allow_any_instance_of(Site).to receive(:save!).and_raise(StandardError.new('Unknown error'))
        end

        it 'raises a SubsiteImportError with the original error message' do
          expect { import.import_subsite }.to raise_error(Exceptions::SubsiteUploadError, /Unknown error/)
        end
      end
    end

    # Testing a signature-image upload
    context 'when importing a subsite with image data' do
      let(:test_import_path_with_image) { File.join(fixture_path, 'test_import_with_image.zip') }
      let(:import) { SubsiteImportService.new(test_import_path_with_image, true) }
      let(:images_dir) { File.join(Rails.root, 'public', 'images', 'sites', 'dlc_site') }
      let(:signature_image_path) { File.join(images_dir, 'signature-banner.png') }

      before do
        FileUtils.remove_dir images_dir if Dir.exist? images_dir # just in case
        import.import_subsite
      end

      after do
        FileUtils.remove_dir images_dir
      end

      context 'when the image is new' do
        it 'creates the image directory' do
          expect(Dir.exist?(images_dir)).to be_truthy
        end
        it 'saves the image to the file system' do
          expect(File).to exist(signature_image_path)
        end
      end

      context 'when the image is a replacement' do
        before do
          FileUtils.mkdir_p images_dir
          File.write signature_image_path, 'test image content'
        end

        it 'replaces the existing image' do
          File.read signature_image_path do |file_content|
            expect(file_content).not_to eql('test image content')
          end
        end
      end
    end

    context 'with an invalid import' do
      context 'when the zip file is missing site metadata' do
        let(:invalid_import_path) { File.join(fixture_path, 'bad_no_site_metadata.zip') }
        let(:import) { SubsiteImportService.new(invalid_import_path, true) }

        it 'raises a validation error' do
          expect { import.import_subsite }.to raise_error(Exceptions::SubsiteUploadValidationError)
        end
      end

      context 'when the zip file has the wrong site metadata filename' do
        let(:invalid_import_path) { File.join(fixture_path, 'bad_site_metadata_filename.zip') }
        let(:import) { SubsiteImportService.new(invalid_import_path, true) }

        it 'raises a validation error' do
          expect { import.import_subsite }.to raise_error(Exceptions::SubsiteUploadValidationError)
        end
      end

      context 'when the zip file has no home page' do
        let(:invalid_import_path) { File.join(fixture_path, 'bad_no_home_page.zip') }
        let(:import) { SubsiteImportService.new(invalid_import_path, true) }

        it 'raises a validation error' do
          expect { import.import_subsite }.to raise_error(Exceptions::SubsiteUploadValidationError)
        end
      end

      context 'when the zip file has bad metadata file' do
        let(:invalid_import_path) { File.join(fixture_path, 'bad_page_metadata_filename.zip') }
        let(:import) { SubsiteImportService.new(invalid_import_path, true) }

        it 'raises a validation error' do
          expect { import.import_subsite }.to raise_error(Exceptions::SubsiteUploadValidationError)
        end
      end

      context 'when the zip file has bad page markdown file' do
        let(:invalid_import_path) { File.join(fixture_path, 'bad_page_markdown_filename.zip') }
        let(:import) { SubsiteImportService.new(invalid_import_path, true) }

        it 'raises a validation error' do
          expect { import.import_subsite }.to raise_error(Exceptions::SubsiteUploadValidationError)
        end
      end

      context 'when the zip file has bad page markdown metadata (non-matching filename)' do
        let(:invalid_import_path) { File.join(fixture_path, 'bad_page_metadata_markdown_field.zip') }
        let(:import) { SubsiteImportService.new(invalid_import_path, true) }

        it 'raises a validation error' do
          expect { import.import_subsite }.to raise_error(Exceptions::SubsiteUploadValidationError)
        end
      end

      context 'when the zip file has bad image file' do
        let(:invalid_import_path) { File.join(fixture_path, 'bad_signature_image.zip') }
        let(:import) { SubsiteImportService.new(invalid_import_path, true) }

        it 'raises a validation error' do
          expect { import.import_subsite }.to raise_error(Exceptions::SubsiteUploadValidationError)
        end
      end
    end
  end
end
