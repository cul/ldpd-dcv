# frozen_string_literal: true

require 'rails_helper'

describe 'React application', type: :feature, js: true do
  let(:admin) { FactoryBot.create(:user, is_admin: true) }
  let(:editor) { FactoryBot.create(:user, uid: 'te123') }
  let(:user) { FactoryBot.create(:user, uid: 'tu123') }

  before do
    FactoryBot.create(:site, editor_uids: ['te123'], slug: 'test_site')
    FactoryBot.create(:site, editor_uids: [], slug: 'test_site2')
    FactoryBot.create(:site, editor_uids: [], slug: 'test_site3')
  end

  describe '/admin' do
    let(:endpoint) { '/admin'}

    context 'when admin user' do
      it 'shows the admin dashboard' do
        Warden.test_mode!
        login_as admin, scope: :user
        visit endpoint
        expect(page).to have_content('DLC Admin Homepage')
      end
    end

    context 'when editor user' do
      before do
        Warden.test_mode!
        login_as editor, scope: :user
      end

      it 'shows error' do
        visit endpoint
        expect(page).to have_content('You are not authorized to access this page.')
      end
    end

    context 'when normal user' do
      before do
        Warden.test_mode!
        login_as user, scope: :user
      end

      it 'shows error' do
        visit endpoint
        expect(page).to have_content('You are not authorized to access this page.')
      end
    end

    context 'when unauthenticated' do
      it 'does not render react app' do
        visit endpoint
        expect(page).not_to have_css '#root'
      end
    end
  end

  describe '/admin/sites' do
    let(:endpoint) { '/admin/sites'}

    context 'when admin user' do
      before do
        Warden.test_mode!
        login_as admin, scope: :user
        visit endpoint
      end
      it 'shows the subsites dashboard' do
        expect(page).to have_content('DLC Subsites Admin Dashboard')
      end
    end

    context 'when editor user' do
      before do
        Warden.test_mode!
        login_as editor, scope: :user
      end

      it 'shows the subsites dashboard' do
        visit endpoint
        expect(page).to have_content('DLC Subsites Editor Dashboard')
      end
    end

    context 'when normal user' do
      before do
        Warden.test_mode!
        login_as user, scope: :user
      end

      it 'shows error' do
        visit endpoint
        expect(page).to have_content('You are not authorized to access this page.')
      end
    end
  end
end