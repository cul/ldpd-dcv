module FieldDisplayHelpers::LocationUrls
  def solr_url_hash(document, opts = {})
    candidates = JSON.parse(document.fetch(:location_url_json_ss, "[]"))
    exclude = opts.fetch(:exclude, {})
    candidates.select do |c|
      !c.detect { |k,v| exclude[k] == v }
    end
  end
end