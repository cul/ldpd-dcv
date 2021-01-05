module FieldDisplayHelpers::Subject
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
end