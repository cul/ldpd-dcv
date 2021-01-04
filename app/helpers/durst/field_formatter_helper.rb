module Durst::FieldFormatterHelper

	def capitalize_values(value)
		return value.capitalize
	end

	def split_complex_subject_into_links(args)
		values = args[:document][args[:field]]

		values.map do |value|
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
		end
	end
	
	def render_durst_location_information(document)
		
		sublocation = document['lib_sublocation_ssm'].present? ? document['lib_sublocation_ssm'][0] : ''
		collection = document['lib_collection_ssm'].present? ? document['lib_collection_ssm'][0] : ''
		shelf_location = document['location_shelf_locator_ssm'].present? ? document['location_shelf_locator_ssm'][0] : ''
		
		# Example output: "Avery Classics Collection, Seymour B. Durst Old York Library Collection, Box no. 35, Item no. 353."
		return	(
			'<dl class="dl-horizontal">' +
				'<dt>Location:</dt>' +
				'<dd>' + (link_to(sublocation, 'http://library.columbia.edu/locations/avery/classics.html') + ', ' + collection + ', ' + shelf_location + '.') + '</dd>' +
			'</dl>'
		).html_safe
    end
	
	def combined_field_published_string(document)

    publisher = document['lib_publisher_ssm'].present? ? document['lib_publisher_ssm'].first.strip : ''
    origin_info_place = document['origin_info_place_for_display_ssm'].present? ? document['origin_info_place_for_display_ssm'].first.strip : ''
    date_to_display = document['lib_date_textual_ssm'].present? ? document['lib_date_textual_ssm'].first.strip : ''

		combined_string = "#{origin_info_place} : #{publisher}, #{date_to_display}".strip
		
		# If combined_string begins with a colon, that means that origin_info_place was not present.  Remove leading colon.
		combined_string = combined_string[1...combined_string.length].strip if combined_string.start_with?(':')
		# If combined string contains ': ,', that means that lib_publisher_ssm was not present.  Remove that snippet if it exists.
		combined_string = combined_string.gsub(': ,', '')
		# If combined_string starts with ', ', that means that neither publisher nor origin_info_place were present.  Remove this leading ', '
		combined_string = combined_string[2...combined_string.length].strip if combined_string.start_with?(', ')
		# If combined_string ends with a colon, that means date_to_display was not present.  Remove trailing comma
		combined_string = combined_string[0...combined_string.length-1].strip if combined_string.end_with?(',')

		return combined_string
  end

end
