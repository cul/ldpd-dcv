require 'zip'

DB_FIELDS = ['id', 'created_at', 'site_id', 'site_page_id', 'updated_at']

class SubsiteExportService
  def initialize(subsite)
    @subsite = subsite
  end

  def create_zipped_export
    # For now, let's try to create the zip in memory:
    stream = Zip::OutputStream.write_buffer do |zos|
      write_subsite_properties(zos)
      # write_images(zos)
      # write_pages(zos)
    end
    stream.rewind
    stream
  end

  private

  # Creates the top-level properties.yml file
  # Users can optionally include ActiveRecord-specific fields by passing db_fields true
  def write_subsite_properties(zos, db_fields = false)
    zos.put_next_entry('properties.yml')
    json = @subsite.as_json(include: {scope_filters: {}, nav_links: {}, permissions: {compact: true}, search_configuration: {compact: true}})
    unless db_fields
      DB_FIELDS.each { |f| json.delete(f) }
      json.delete('constraints') # obsolete
      json['scope_filters'].each do |filter|
        DB_FIELDS.each { |f| filter.delete(f) }
        filter.delete('scopeable_id')
        filter.delete('scopeable_type')
      end
      json['nav_links'].each do |nav_link|
        DB_FIELDS.each { |f| nav_link.delete(f) }
      end
    end
    yaml = YAML.dump(json)
    puts yaml
    zos.write(yaml)
  end

  def write_images(zos)

  end

  def write_pages(zos)

  end
end