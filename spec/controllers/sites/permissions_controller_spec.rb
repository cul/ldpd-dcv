require 'rails_helper'

describe Sites::PermissionsController, type: :unit do
	let(:controller) { described_class.new }
	let(:params) {
		ActionController::Parameters.new(
			site_slug: site.slug
		)
	}
	let(:site) { FactoryBot.create(:site) }
	let(:request_double) { instance_double('ActionDispatch::Request') }
	before do
		allow(request_double).to receive(:host).and_return('localhost')
		allow(request_double).to receive(:optional_port)
		allow(request_double).to receive(:protocol)
		allow(request_double).to receive(:path_parameters).and_return({})
		allow(request_double).to receive(:flash).and_return({})
		allow(controller).to receive(:params).and_return(params)
		allow(controller).to receive(:request).and_return(request_double)
		allow(controller).to receive(:load_subsite).and_return(site)
		controller.instance_variable_set(:@subsite, site)
	end
	describe '#site_params' do
		let(:is_admin) { false }
		before do
			controller.instance_variable_set(:@subsite, site)
			allow(controller).to receive(:can?).with(:admin, site).and_return(is_admin)
		end
		context 'with editor_uids text' do
			let(:uids) { ['abc', 'bcd', 'cde'] }
			let(:editor_param) { uids.join(",") }
			let(:params) {
				ActionController::Parameters.new(
					site: {
						editor_uids: editor_param
					}
				)
			}
			let(:update_params) { controller.send :permissions_params }
			context 'with admin' do
				let(:is_admin) { true }
				it "parses the value array" do
					expect(update_params[:editor_uids]).to eql(uids)
				end
				context 'and loose formatting of input data' do
					let(:editor_param) { uids.join("\n ,") }
					it "parses the value array" do
						expect(update_params[:editor_uids]).to eql(uids)
					end
				end
			end
			context 'not admin' do
				it "removes proposed values" do
					expect(update_params[:editor_uids]).to eql(site.editor_uids)
				end
			end
		end
	end
	describe '#update' do
		let(:permissions_fixture) { YAML.load(fixture("yml/site_permissions.yml").read).freeze }
		let(:rails_param_hash) do
			permissions_fixture
		end
		let(:params) {
			ActionController::Parameters.new(
				site_slug: site.slug,
				site: rails_param_hash
			)
		}
		before do
			allow(controller).to receive(:authorize_site_update).and_return(true)
			allow(controller).to receive(:can?).with(:admin, site).and_return(true)
			expect(controller).to receive(:redirect_to).with("/#{site.slug}/permissions/edit")
		end
		context 'local search' do
			let(:site) { FactoryBot.create(:site, search_type: 'local') }
			it do
				controller.update
				expect(controller.flash[:notice]).to eql('Saved!')
				expected_editors = permissions_fixture['editor_uids'].split(',')
				expect(site.reload.editor_uids).to be_eql(expected_editors)
				expected_permissions_atts = permissions_fixture['permissions'].dup
				expected_permissions_atts['remote_ids'] = expected_permissions_atts['remote_ids'].split(',')
				expect(site.reload.permissions.as_json).to be_eql(Site::Permissions.new(expected_permissions_atts).as_json)
				expect(site.reload.permissions.as_json).not_to be_eql(Site::Permissions.new.as_json)
			end
		end
	end
end
