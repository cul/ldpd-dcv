require 'rails_helper'

describe SitesController, type: :feature do
  describe "show" do
    before do
      visit site_url('internal_site')
    end
    it "should render the markdown description" do
      expect(page).to have_xpath('/descendant::li/a', text: 'Avery Architectural & Fine Arts Library')
    end
  end
  describe "index" do
    before { visit root_url }
    it "links to tabs" do
      expect(page).to have_xpath("/descendant::a[@href='#projects' and @data-toggle='tab']")
      expect(page).to have_xpath("/descendant::a[@href='#tab_lib_name_sim' and @data-toggle='tab']")
      expect(page).to have_xpath("/descendant::a[@href='#tab_lib_format_sim' and @data-toggle='tab']")
      expect(page).to have_xpath("/descendant::a[@href='#tab_lib_repo_long_sim' and @data-toggle='tab']")
      expect(page).to have_xpath("/descendant::a[@href='#other-collections' and @data-toggle='tab']")
    end
    context 'in the projects div' do
      it "links to internal_site" do
        expect(page).to have_xpath("//div[@id='projects']")
        expect(page).to have_xpath("//div[@id='projects']/descendant::div[@role='group']/a[@href='#{site_url('internal_site')}' and @itemprop='url']")
        expect(page).to have_xpath("//div[@id='projects']/descendant::div[@itemprop='name']", text: 'Internal Library Project Online')
      end
      it "does not link to external_site" do
        expect(page).not_to have_xpath("//div[@id='projects']/descendant::div[@role='group']/a[@href='https://external.library.columbia.edu' and @itemprop='url']")
        expect(page).not_to have_xpath("//div[@id='projects']/descendant::div[@itemprop='name']", text: 'External Library Project Online')
      end
      it "links to internal_site content with facet value" do
        expect(page).to have_xpath("//div[@id='projects']/descendant::div[@role='group']/a[@href='/catalog?f%5Blib_project_short_ssim%5D%5B%5D=Internal+Project' and @title='Browse Content']")
      end
    end
    context 'in the other-collections div' do
      it "links to internal_site" do
        expect(page).to have_xpath("//div[@id='other-collections']/descendant::div[@role='group']/a[@href='#{site_url('internal_site')}' and @itemprop='url']")
        expect(page).to have_xpath("//div[@id='other-collections']/descendant::div[@itemprop='name']", text: 'Internal Library Project Online')
      end
      it "links to external_site at source url" do
        expect(page).to have_xpath("//div[@id='other-collections']/descendant::div[@role='group']/a[@href='https://external.library.columbia.edu' and @itemprop='url']")
        expect(page).to have_xpath("//div[@id='other-collections']/descendant::div[@itemprop='name']", text: 'External Library Project Online')
      end
      it "links to internal_site content with facet value" do
        expect(page).to have_xpath("//div[@id='other-collections']/descendant::div[@role='group']/a[@href='/catalog?f%5Blib_project_short_ssim%5D%5B%5D=Internal+Project' and @title='Browse Content']")
      end
    end
    it "doesn't link to external_site content with facet value" do
      expect(page).not_to have_xpath("//div[@role='group']/a[@href='/catalog?f%5Blib_project_short_ssim%5D%5B%5D=External+Project']")
    end
    it "doesn't link to catalog, sites" do
      expect(page).not_to have_xpath("//div[@role='group']/a[@href='/sites/catalog']")
      expect(page).not_to have_xpath("//div[@role='group']/a[@href='/sites/sites']")
    end
  end
end
