module Durst::UrlHelper

	def durst_image_search_url
		return url_for({controller: 'durst', action: 'index', search_field: 'all_text_teim', q: '', 'f' => {'lib_format_sim' => (durst_format_list.keys.reject{|key| key == 'books'})}})
	end

	def durst_subject_search_url(subject_term_value)
		return url_for({controller: 'durst', action: 'index', search_field: 'all_text_teim', q: '', 'f' => {'durst_subjects_ssim' => [subject_term_value]}})
	end

end
