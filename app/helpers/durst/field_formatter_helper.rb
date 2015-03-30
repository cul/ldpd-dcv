module Durst::FieldFormatterHelper

	def capitalize_values(value)
		return value.capitalize
  end

	def split_complex_subject_into_links(args)
    values = args[:document][args[:field]]

    values.map {|value|
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
			links.join(' > ').html_safe
		}

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

	def combined_field_published_string(args)
		# Note: This helper will only run when a publisher is present.

    publisher = args[:document]['lib_publisher_ssm'].present? ? args[:document]['lib_publisher_ssm'].first.strip : ''
    origin_info_place = args[:document]['origin_info_place_for_display_ssm'].present? ? args[:document]['origin_info_place_for_display_ssm'].first.strip : ''
    date_to_display = args[:document]['lib_date_year_range_ss'].present? ? args[:document]['lib_date_year_range_ss'].strip : ''

    # If the starts and end of the year range are the same, compress them into one year
    if date_to_display.index('-')
			start_and_end = date_to_display.split('-')
			if start_and_end[0] == start_and_end[1]
				date_to_display = start_and_end[0]
			end
		end

		combined_string = "#{origin_info_place} : #{publisher}, #{date_to_display}".strip

		# If combined_string begins with a colon, that means no origin_info_place was present.  Remove leading colon.
		combined_string = combined_string[1...combined_string.length].strip if combined_string.start_with?(':')
		# If combined_string ends with a colon, that means no date_to_display was present.  Remove trailing comma
		combined_string = combined_string[0...combined_string.length-1].strip if combined_string.end_with?(',')

		return combined_string
  end

end
