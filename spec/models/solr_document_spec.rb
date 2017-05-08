require 'rails_helper'
describe SolrDocument do
  subject { SolrDocument.new(doc) }
  context 'is a site result' do
    let(:doc) { {dc_type_ssm: ['Publish Target']} } 
    it { is_expected.to be_site_result }
  end
  context 'is not a site result' do
    let(:doc) { {dc_type_ssm: ['Unpublish Target']} } 
    it { is_expected.not_to be_site_result }
  end
end