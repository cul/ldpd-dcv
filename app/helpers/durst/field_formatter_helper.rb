module Durst::FieldFormatterHelper

	def capitalize_values(value)
		return value.capitalize
  end

	def split_complex_subject_into_links(args)
    value = args[:document][args[:field]][0]

    links = []
    previous_subjects = []

    value.split('--').each do |single_subject|
			links << link_to(single_subject, search_action_path({
					:q => '"' + "#{previous_subjects.join(' ')} #{single_subject}".strip + '"',
					:search_field => 'all_text_teim'
				})
			)
			previous_subjects << single_subject
		end

    return links.join(' > ').html_safe
  end

	def render_url_and_catalog_links(document, as_dl=true)

    urls = document['lib_non_item_in_context_url_ssm'] || []
    clio_ids = document['clio_ssim'] || []

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
