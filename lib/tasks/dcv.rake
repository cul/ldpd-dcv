namespace :dcv do

  namespace :rails_cache => :environment do
    task :clear => :environment do
      Rails.cache.clear
    end
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

  namespace :css do
    task :fix => :environment do
      open('caggs_css.txt') do |blob|
        i = 0
        j = 0
        blob.each do |line|
          line.strip!
          obj = ContentAggregator.find(line)
          mods = obj.datastreams['descMetadata']
          old_content = mods.content
          new_content = old_content.gsub(/\<originInfo/,'<mods:originInfo')
          new_content ||= old_content
          new_content = new_content.gsub(/\/originInfo/,'/mods:originInfo') || new_content
          if new_content
            mods.content = new_content
            obj.save
            j = j + 1
          end
          i = i + 1
          p "processed #{i} of 1348 modifying #{j}\n"
        end
      end
    end
  end

end
