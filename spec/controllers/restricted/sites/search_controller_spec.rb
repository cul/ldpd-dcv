require 'rails_helper'

describe Restricted::Sites::SearchController, :type => :controller do
	describe '#show' do
		let(:site) { FactoryBot.create(:site, slug: 'restricted/test_site', layout: 'default', palette: 'default', restricted: true) }
		let(:params) {
			{
				site_slug: site.slug,
				id: '10.7916/D8RN3JX8'
			}
		}
		let(:current_user) { FactoryBot.create(:user) }
		let(:remote_ip) { '255.255.255.255' }
		let(:request_double) { instance_double('ActionDispatch::Request') }
		before do
			allow(request_double).to receive(:host).and_return('localhost')
			allow(request_double).to receive(:optional_port)
			allow(request_double).to receive(:protocol)
			allow(request_double).to receive(:remote_ip).and_return(remote_ip)
			allow(request_double).to receive(:path_parameters).and_return({})
			allow(request_double).to receive(:flash).and_return({})
			controller.instance_variable_set(:@subsite, site)
			allow(controller).to receive(:current_user).and_return(current_user)
		end
		context 'unauthorized user' do
			it "denies access" do
				expect(controller).to receive(:access_denied)
				get :show, params: params
			end
		end
		context 'authorized user by role' do
			let(:role) { 'LIB-Test-Role' }
			before do
				controller.session["cul.roles"] = [role]
				site.permissions.remote_roles = [role]
				site.save
			end
			it "permits access" do
				# solr doc is referenced in respond_to block
				expect(controller).to receive(:fetch).and_return([nil, SolrDocument.new])
				expect(controller).to receive(:render).with('show').and_return(nil)
				allow(controller).to receive(:render).with no_args
				get :show, params: params
			end
		end
		context 'authorized user by id' do
			before do
				site.permissions.remote_ids = [current_user.uid]
				site.save
			end
			it "permits access" do
				# solr doc is referenced in respond_to block
				expect(controller).to receive(:fetch).and_return([nil, SolrDocument.new])
				expect(controller).to receive(:render).with('show').and_return(nil)
				allow(controller).to receive(:render).with no_args
				get :show, params: params
			end
		end
	end
end
