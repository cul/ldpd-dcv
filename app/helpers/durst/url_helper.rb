module Durst::UrlHelper
	FORMAT_LIST = ["books", "postcards", "other", "periodicals", "maps", "ephemera", "objects", "manuscripts", "music"].map {|k| [k, k.capitalize]}.to_h.freeze

	def durst_format_list
		FORMAT_LIST
	end

	def durst_image_search_url
		local_facet_search_url('lib_format_sim', durst_format_list.keys.reject{|key| key == 'books'})
	end
end
