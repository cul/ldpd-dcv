module Durst::SearchFormHelper

	def durst_format_list
	  return {
		"books" => "Books",
		"objects" => "Objects",
		"postcards" => "Postcards",
		"prints" => "Prints"
	  }
	end

end
