module Durst::FieldFormatterHelper

	def capitalize_values(value)
		return value.capitalize
  end

	def render_online_and_print_links(document, as_dl=true)

    urls = document['location_url_ssm'] || []
    clio_ids = document['bib_id_physical_ssm'] || []

    if as_dl
      return (
        '<dl class="dl-horizontal">' +
        (urls.length == 0 ? '' : '<dt>Online:</dt><dd> ' + urls.map{|url| link_to('click here for full-text <span class="glyphicon glyphicon-new-window"></span>'.html_safe, url, target: '_blank') }.join('</dd><dt></dt><dd>') + '</dd>') +
        (clio_ids.length == 0 ? '' : '<dt>Catalog Record:</dt><dd> ' + clio_ids.map{|clio_id| link_to('check availability <span class="glyphicon glyphicon-new-window"></span>'.html_safe, 'http://clio.columbia.edu/catalog/' + clio_id, target: '_blank') }.join('</dd><dt></dt><dd>') + '</dd>') +
        '</dl>'
      ).html_safe
    else
      return (
        (urls.length == 0 ? '' : '<strong>Online:</strong> ' + urls.map{|url| link_to('click here for full-text <span class="glyphicon glyphicon-new-window"></span>'.html_safe, url, target: '_blank') }.join('; ')) +
        (urls.length > 0 && clio_ids.length > 0 ? '<br />' : '') +
        (clio_ids.length == 0 ? '' : '<strong>Catalog Record:</strong> ' + clio_ids.map{|clio_id| link_to('check availability <span class="glyphicon glyphicon-new-window"></span>'.html_safe, 'http://clio.columbia.edu/catalog/' + clio_id, target: '_blank')}.join('; '))
      ).html_safe
    end



	end

end
