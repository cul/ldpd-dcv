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
	
end
