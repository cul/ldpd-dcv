require 'rails_helper'

describe Nyre::ProjectsController, type: :feature do
  before do
    @orig_config = SUBSITES['public']['nyre']
    SUBSITES['public']['nyre'] = {
      layout: 'nyre',
      map_search: {
        sidebar: true,
        default_lat: 40.757,
        default_long: -73.981,
        default_zoom: 11
      },
      remote_request_api_key:'goodtoken'
    }
  end
  after do
    SUBSITES['public']['nyre'] = @orig_config
  end
  describe '#show' do
    let(:project) { Nyre::Project.first }
    before do
      visit nyre_project_path(project)
    end
    it "has a Call Number" do
      expect(page).to have_css('dt', text: 'Call Number')
      expect(page).to have_css('dd', text: project.call_number)
    end
  end
end
