# frozen_string_literal: true

shared_context 'as admin user' do
  let(:admin) { FactoryBot.create(:user, is_admin: true) }
  
  before do
    sign_in admin
  end
end

shared_context 'as editor user' do
  # Note this UID because it should be passed to site factories to create editor relationship
  let(:editor) { FactoryBot.create(:user, uid: 'te123') }
  
  before do
    sign_in editor
  end
end

shared_context 'as non-privileged user' do
  let(:user) { FactoryBot.create(:user, uid: 'tu123') }
  
  before do
    sign_in user
  end
end