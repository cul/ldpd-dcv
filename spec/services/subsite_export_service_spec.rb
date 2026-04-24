require 'rails_helper'

RSpec.describe SubsiteExportService do
  let(:site) { FactoryBot.create(:site_with_links) }
	let!(:page) { FactoryBot.create(:site_page_with_text_blocks, site: site, slug: 'home', title: 'Home' ) }
  let(:test_export) { SubsiteExportService.new(site)}

  def extract_files(zip_io)
    entries = {}
    Zip::File.open_buffer zip_io do |zip|
      zip.each do |entry|
        entries[entry.name] = entry.get_input_stream.read
      end
    end
    entries
  end

  describe 'create_zipped_export' do
    let(:export) { test_export.create_zipped_export }
    let(:files) { extract_files(export) }
    let(:metadata_file) { Dcv::Sites::Constants::SITE_METADATA }
    let(:pages_subdir) { Dcv::Sites::Constants::PAGES_SUBDIR }


    it 'returns a zip file stream' do
      expect(export).to be_instance_of StringIO
    end

    describe 'site metadata file' do
      it 'creates the right file' do
        expect(files.key? metadata_file).to be_truthy
      end

      describe 'writes the correct metadata to the file' do
        let(:site_metadata) { YAML.load files[metadata_file] }

        it 'has the correct slug' do
          expect(site_metadata['slug']).to eql('dlc_site')
        end

        it 'has the correct title' do
          expect(site_metadata['title']).to eql('DLC Site')
        end

        it 'has the correct persistent_url' do
          expect(site_metadata['persistent_url']).to eql('https://example.com/catalog/persistent_url')
        end

        it 'has the correct restricted value' do
          expect(site_metadata['restricted']).to be_falsy
        end

        it 'has the correct layout' do
          expect(site_metadata['layout']).to eql('default')
        end

        it 'has the correct palette' do
          expect(site_metadata['palette']).to eql('monochromeDark')
        end

        it 'has the correct search_type' do
          expect(site_metadata['search_type']).to eql('catalog')
        end

        it 'has the correct image_uris' do
          expect(site_metadata['image_uris'].first).to eql('info:fedora/test-image:1')
        end

        it 'has the correct repository_id' do
          expect(site_metadata['repository_id']).to eql('NNC')
        end

        it 'has the correct scope filters' do
          scope_filter = site_metadata['scope_filters'].first
          expect(scope_filter['filter_type']).to eql('collection')
          expect(scope_filter['value']).to eql('DLC Site Collection')
        end

        describe 'nav links' do
          let(:nav_links) { site_metadata['nav_links'] }

          it 'has the correct number of nav links' do
            expect(nav_links.length).to eql(3)
          end

          it 'has the correct nav link values' do
            about_link = nav_links.find { |nav_link| nav_link['link'] == 'about' }
            expect(about_link['sort_label']).to eql('About')
            funding_link = nav_links.find { |nav_link| nav_link['link'] == 'funding' }
            expect(funding_link['sort_label']).to eql('Funding')
            expect(funding_link['sort_group']).to eql('01:Project History')
            contributors_link = nav_links.find { |nav_link| nav_link['link'] == 'contributors' }
            expect(contributors_link['sort_label']).to eql('Contributors')
            expect(contributors_link['sort_group']).to eql('01:Project History')
          end
        end
      end
    end
    describe 'page metadata files' do
      let(:home_page_metadata_file_name) { "#{pages_subdir}/home/#{metadata_file}" }
      let(:home_page_metadata_file) { files[home_page_metadata_file_name]}
      
      it 'creates the right files' do
        expect(files.key? home_page_metadata_file_name).to be_truthy
      end

      describe 'writes correct metadata to the file' do
        let(:home_page_metadata) { YAML.load home_page_metadata_file }

        it 'has the right slug' do
          expect(home_page_metadata['slug']).to eql('home')
        end

        it 'has the right title' do
          expect(home_page_metadata['title']).to eql('Home')
        end

        it 'has the right columns' do
          expect(home_page_metadata['columns']).to eql(1)
        end

        describe 'text blocks' do
          let(:text_blocks) { home_page_metadata['site_page_text_blocks'] }

          it 'has the right number of text blocks' do
            expect(text_blocks.length).to eql(1)
          end
          it 'has the right sort labels' do
            expect(text_blocks.first['sort_label']).to eql('00:Text Block')
          end
          it 'has the right markdown filename' do
            expect(text_blocks.first['markdown']).to eql('00_Text_Block.md')
          end
        end

        describe 'page markdown files' do
          let(:home_page_markdown_file) { "#{pages_subdir}/home/00_Text_Block.md" }
          it 'has the markdown file' do
            expect(files.key? home_page_markdown_file).to be_truthy
          end
          it 'has the markdown content in the file' do
            expect(files[home_page_markdown_file]).to eql("# Hello")
          end
        end
      end
    end

    describe 'image assets' do
      let(:images_dir) { File.join(Rails.root, 'public', 'images', 'sites', site.slug) }
      let(:image_file_name) { 'test_image.png' }
      let(:image_path) { File.join(images_dir, image_file_name) }
      let(:image_file_zip) { "#{Dcv::Sites::Constants::IMAGES_SUBDIR}/#{image_file_name}"}

      before do
        FileUtils.mkdir_p images_dir
        File.write image_path, 'test image content'
      end

      after do
        FileUtils.remove_dir images_dir
      end

      it 'includes any images' do
        expect(files.key? image_file_zip).to be_truthy
      end

      it 'zips the correct image content' do
        expect(files[image_file_zip]).to eql('test image content')
      end
    end
  end
end
