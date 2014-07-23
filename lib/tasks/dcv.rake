namespace :dcv do

  task :test => :environment do
    puts 'This is just a test rake task'
  end
  namespace :index do
    task :list => :environment do
      list = ENV['list']
      pids = []
      open(list) do |blob|
        blob.each do |line|
          pids << line.strip
        end
      end
      Rails.logger.level = Logger::INFO
      len = pids.length
      current = 0
      pids.each do |pid|
        current += 1
        active_fedora_object = ActiveFedora::Base.find(pid, :cast => true)
        active_fedora_object.update_index
        Rails.logger.info "indexed #{current} of #{len}"
        sleep(3) if current % 100 == 0
      end
    end
  end
end
