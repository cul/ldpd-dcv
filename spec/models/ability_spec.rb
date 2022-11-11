require 'rails_helper'
describe Ability do
	context 'restricted site' do
		let(:remote_ip) { Rails.application.config_for(:location_uris).first[1][:remote_ip].first }
		let(:current_user) { FactoryBot.create(:user) }
		let(:affils) { ['userAffil'] }
		let(:locations) { Rails.application.config_for(:location_uris).keys }
		let(:current_ability) { Ability.new(current_user, roles: affils, remote_ip: remote_ip) }
		let(:site) { FactoryBot.create(:site, slug: "restricted/site_slug", restricted: true) }
		it 'denies access' do
			expect(current_ability.can?(Ability::ACCESS_SUBSITE, site)).to be false
		end
		it 'does have a truthy public attribute when there is NO context' do
			expect(Ability.new.public).to be true
		end
		it 'does not have a truthy public attribute when there is context' do
			expect(current_ability.public).to be false
		end
		context 'user is in remote IDs for site' do
			before do
				site.permissions.remote_ids = [current_user.uid]
				site.save
			end
			it 'permits access' do
				expect(current_ability.can?(Ability::ACCESS_SUBSITE, site)).to be true
			end
		end
		context 'user affils in remote roles for site' do
			before do
				site.permissions.remote_roles = affils
				site.save
			end
			it 'permits access' do
				expect(current_ability.can?(Ability::ACCESS_SUBSITE, site)).to be true
			end
		end
		context 'remote IP maps to location for site' do
			before do
				site.permissions.locations = locations
				site.save
			end
			it 'permits access' do
				expect(current_ability.can?(Ability::ACCESS_SUBSITE, site)).to be true
			end
		end
	end

end