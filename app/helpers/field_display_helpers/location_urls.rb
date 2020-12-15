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
      link_label = "#{display_label} <sup class=\"glyphicon glyphicon-new-window\" aria-hidden=\"true\"></sup>"
      link_to(link_label.html_safe, location['url'], target: "_blank", rel: "noopener noreferrer")
    end
  end
end