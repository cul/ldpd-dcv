class DeviseCreateDefaultUserAccounts < ActiveRecord::Migration
  def change

    if File.exists?('config/default_user_accounts.yml')
      YAML.load_file('config/default_user_accounts.yml').each {|service_user_entry, service_user_info|
        User.create(
          :email => service_user_info['email'],
          :password => service_user_info['password'],
          :password_confirmation => service_user_info['password'],
          :first_name => service_user_info['first_name'],
          :last_name => service_user_info['last_name'],
          :is_admin => service_user_info['is_admin']
        )
      }
    end

  end
end
