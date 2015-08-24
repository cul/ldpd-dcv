class AddOmniauthToUsers < ActiveRecord::Migration
  def change
    add_column :users, :provider, :string
    add_index :users, :provider
    add_column :users, :uid, :string
    add_index :users, :uid
    User.all.each do |user|
      user.provider = :saml if user.email.split('@').last.eql?('columbia.edu')
      user.uid = user.email.split('@').first
      user.save!
    end
  end
end
