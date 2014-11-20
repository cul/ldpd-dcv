module Durst::UrlHelper

	def durst_image_search_url
		return url_for({controller: 'durst', action: 'index', search_field: 'all_text_teim', q: '', 'f' => {'lib_format_sim' => (durst_format_list.keys.reject{|key| key == 'books'})}})
	end

	def durst_book_search_url
		return url_for({controller: 'durst', action: 'index', search_field: 'all_text_teim', q: '', 'f' => {'lib_format_sim' => ['books']}})
	end

end
