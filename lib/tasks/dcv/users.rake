namespace :dcv do
	namespace :users do
		task set: :environment do
			puts "Warning: Looking up developer strategy user because provider was not set" unless ENV['provider']
			provider = ENV['provider'] || 'developer'
			user = User.find_by(uid: ENV['uid'], provider: provider)
			unless user
				if ENV['email']
					user = User.create(uid: ENV['uid'], provider: provider, email: ENV['email'])
				else
					puts "Error: cannot create a user without an email"
				end
			end
			next unless user
			['first_name', 'last_name', 'email'].each do |property|
				next unless ENV[property]
				user.send(:"#{property}=", ENV[property])
			end
			# Rails 5 will require explicitly casting to boolean
			['is_admin', 'guest'].each do |property|
				next unless ENV[property]
				val = nil
				val = true if ENV[property] =~ /true/i
				val = false if ENV[property] =~ /false/i
				user.send(:"#{property}=", val) unless val.nil?
			end
			user.save!
			puts user.inspect
		end
	end
end
