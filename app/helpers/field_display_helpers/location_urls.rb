module FieldDisplayHelpers::LocationUrls
  # parses location_url_json_ss via SolrDocument
  def solr_url_hash(document, opts = {})
    document.solr_url_hash(opts)
  end

  def has_related_urls?(field_config, document)
    solr_url_hash(document, exclude: {'usage' => "primary display"}).present?
  end

  def display_related_urls(args={})
    values = Array(args[:value])
    document = args[:document]
    solr_url_hash(document, exclude: {'usage' => "primary display"}).map do |location|
      display_label = location.fetch('displayLabel',"Related Web Content")
      link_label = "<span class=\"glyphicon glyphicon-paperclip\"></span> #{display_label}"
      link_to(link_label.html_safe, location['url'])
    end
  end
end