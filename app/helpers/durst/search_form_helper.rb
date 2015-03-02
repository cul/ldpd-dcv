module Durst::SearchFormHelper

	def durst_format_list
	  return {
			"books" => "Books",

			"postcards" => "Postcards",
			"other" => "Other",
			"periodicals" => "Periodicals",
			"maps" => "Maps",
			"ephemera" => "Ephemera",
			"objects" => "Objects",
			"manuscripts" => "Manuscripts",
			"music" => "Music"
	  }
	end

end
