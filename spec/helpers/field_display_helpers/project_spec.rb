require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the FieldDisplayHelpers::LocationUrls. For example:
#
# describe FieldDisplayHelpers::LocationUrls do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end

describe FieldDisplayHelpers::Project, :type => :helper do
  include_context "a solr document"
  let(:field_name) { :lib_project_full_ssim }
  let(:solr_data) {
    {
      id: document_id, field_name => field_values
    }
  }
  let(:blacklight_config) do
    config = Blacklight::Configuration.new
    config
  end
  before do
    allow(helper).to receive(:blacklight_config).and_return(blacklight_config)
    allow(helper).to receive(:search_action_path).and_return("/search")
  end
  describe '#show_field_project_to_facet_link' do
    subject { helper.show_field_project_to_facet_link(document: solr_document, field: field_name.to_s) }
    let(:field_values) { ['Project 1', 'Project 2'] }
    context 'field is linked' do
      let(:field_name) { :project_key_ssim }
      let(:field_values) { ['test'] }
      before do
        blacklight_config.add_show_field field_name, label: 'Digital Project', helper_method: :show_field_project_to_facet_link, link_to_search: true
      end
      it { is_expected.to satisfy {|x| x.length == field_values.length} }
      it { is_expected.to satisfy {|x| x[0].include?(">Successful Project Mapping For Full Project Title</a>") } }
    end
    context "field is not linked" do
      before do
        blacklight_config.add_show_field field_name, label: 'Digital Project', helper_method: :show_field_project_to_facet_link, link_to_search: false
      end
      it { is_expected.to satisfy {|x| x.length == 2} }
      it { is_expected.to satisfy {|x| x[0].eql?("Project 1") && x[1].eql?("Project 2") } }
    end
  end
end