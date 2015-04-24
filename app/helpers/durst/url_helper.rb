module Durst::UrlHelper

	def durst_blank_search_url
		return url_for({controller: 'durst', action: 'index', search_field: 'all_text_teim', q: '' })
	end

	def durst_image_search_url
		return url_for({controller: 'durst', action: 'index', search_field: 'all_text_teim', q: '', 'f' => {'lib_format_sim' => (durst_format_list.keys.reject{|key| key == 'books'})}})
	end

	def durst_book_search_url
		return url_for({controller: 'durst', action: 'index', search_field: 'all_text_teim', q: '', 'f' => {'lib_format_sim' => ['books']}})
	end

	def durst_facet_search_url(facet_field_name, value)
		return url_for({controller: 'durst', action: 'index', search_field: 'all_text_teim', q: '', 'f' => {facet_field_name => [value]}})
	end
	
	def durst_subject_search_url(subject_term_value)
		return url_for({controller: 'durst', action: 'index', search_field: 'all_text_teim', q: '', 'f' => {'durst_subjects_ssim' => [subject_term_value]}})
	end

end
