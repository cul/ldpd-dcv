class AddRepositorySiteRecords < ActiveRecord::Migration[6.1]
  # Stub class isolated from the live Site model and its validations/callbacks.
  # This prevents future changes to Site from breaking this migration when
  # running from scratch.
  class Site < ActiveRecord::Base
    self.table_name = 'sites'
    LAYOUT_REPOSITORIES = 'repositories'
    SEARCH_REPOSITORIES = 'repositories'
  end

  def change
    reversible do |direction|
      repository_ids = %w(NNC-A NNC-EA NNC-RB NyNyCAP NyNyCBL NyNyCMA)
      direction.up do
        repository_ids.each do |repository_id|
          site = Site.find_by(slug: repository_id)
          site_atts = {
            repository_id: repository_id,
            layout: Site::LAYOUT_REPOSITORIES,
            search_type: Site::SEARCH_REPOSITORIES,
            title: I18n.t("cul.archives.display_value.#{repository_id.downcase.sub('-', '')}").split(',')[0]
          }
          if site
            site.update(**site_atts)
            site.save
          else
            site = Site.create(**site_atts.merge(slug: repository_id))
          end
        end
      end
      direction.down do
        repository_ids.each { |repository_id| Site.find_by(slug: repository_id)&.destroy }
      end
    end
  end
end
