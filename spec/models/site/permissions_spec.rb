require 'rails_helper'
describe Site::Permissions do
	describe Site::Permissions::Type do
		let(:existing) do
			ex = Site::Permissions.new
			ex.remote_ids = ['adminUser']
			ex
		end
		let(:existing_json) { JSON.dump(existing.as_json(compact: true)) }
		it "initializes a Site::Permissions for new values" do
			site = Site.new
			expect(site.permissions).to be_a Site::Permissions
		end
		it "casts a new Site::Permissions from nil db value" do
			site = Site.instantiate('permissions' => nil)
			expect(site.permissions).to be_a Site::Permissions
		end
		it "casts a new Site::Permissions from json db value" do
			site = Site.instantiate('permissions' => existing_json)
			expect(site.permissions).to be_a Site::Permissions
			expect(site.permissions).to eql existing
		end
	end
end