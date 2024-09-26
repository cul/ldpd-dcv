class AddRepositorySiteRecords < ActiveRecord::Migration[6.1]
  def change
    reversible do |direction|
      repository_ids = %w(NNC-A NNC-EA NNC-RB NyNyCAP NyNyCBL NyNyCMA)
      direction.up do
        repository_ids.each do |repository_id|
          site = Site.find_by(slug: repository_id)
          if site
            site.update(layout: Site::LAYOUT_REPOSITORIES, search_type: Site::SEARCH_REPOSITORIES)
            site.save
          else
            site = Site.create(slug: repository_id, layout: Site::LAYOUT_REPOSITORIES, search_type: Site::SEARCH_REPOSITORIES)
          end
        end
      end
      direction.down do
        repository_ids.each { |repository_id| Site.find_by(slug: repository_id)&.destroy }
      end
    end
  end
end
