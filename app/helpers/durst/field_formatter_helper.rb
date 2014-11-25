module Durst::FieldFormatterHelper

	def render_online_and_print_links(document, as_dl=true)

    urls = document['location_url_ssm'] || []
    clio_ids = document['bib_id_physical_ssm'] || []

    if as_dl
      return (
        '<dl class="dl-horizontal">' +
        urls.map{|url| '<dt>Online <span class="glyphicon glyphicon-link"></span>:</dt><dd>' + link_to('click here for full-text'.html_safe, url, target: '_blank') + '</dd>' }.join('') +
        clio_ids.map{|clio_id| '<dt>Print <span class="glyphicon glyphicon-link"></span>:</dt><dd>' + link_to('check availability'.html_safe, 'http://clio.columbia.edu/catalog/' + clio_id, target: '_blank') + '</dd>' }.join('') +
        '</dl>'
      ).html_safe
    else
      return (
        urls.map{|url| '<strong>Online <span class="glyphicon glyphicon-link"></span>:</strong> ' + link_to('click here for full-text'.html_safe, url, target: '_blank') + '<br />' }.join('') +
        clio_ids.map{|clio_id| '<strong>Print <span class="glyphicon glyphicon-link"></span>:</strong> ' + link_to('check availability'.html_safe, 'http://clio.columbia.edu/catalog/' + clio_id, target: '_blank') + '<br />' }.join('')
      ).html_safe
    end



	end

end
