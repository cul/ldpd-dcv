require 'rails_helper'

describe ::Sites::PermissionsController, type: :feature do
	include_context "site fixtures for features"
	let(:source) { fixture("sites/import/directory").path }
	let(:import) { Dcv::Sites::Import::Directory.new(source) }
	let(:site_slug) { import.atts['slug'] }
	let(:site_layout) { import.atts['layout'] }
	let(:site_link_href) { "/#{site_slug}" }
	let(:edit_link_href) { "/#{site_slug}/permissions/edit" }
	describe '#update' do
		before { import.run }
		let(:authorized_user) { FactoryBot.create(:user, is_admin: true) }
		before do
			Warden.test_mode!
			login_as authorized_user, scope: :user
			visit(edit_link_href)
		end
		it 'updates atts' do
			fill_in('Remote Access UNIs', with: "remoteUser, remoteContributor")
			fill_in('Site Editor UNIs', with: "adminUser, adminPartner")
			click_button "Update Permissions"
			# do a find to make sure page loaded
			find('#site_permissions_remote_ids')
			visit(edit_link_href)
			expect(find_field('Remote Access UNIs').value).to eq("remoteContributor,\nremoteUser")			
			expect(find_field('Site Editor UNIs').value).to eq("adminPartner,\nadminUser")			
		end
	end
	describe '#edit' do
		before do
			import.run
			Warden.test_mode!
			login_as authorized_user, scope: :user
			visit(edit_link_href)
		end
		let(:authorized_user) { FactoryBot.create(:user, is_admin: true) }
		it "includes a link to view the site" do
			expect(page).to have_link('View Site', href: site_link_href)
		end
	end
end