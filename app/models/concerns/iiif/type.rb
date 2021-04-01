module Iiif::Type
	module V3
		DATASET = 'Dataset'
		IMAGE   = 'Image'
		MODEL   = 'Model'
		SOUND   = 'Sound'
		TEXT    = 'Text'
		VIDEO   = 'Video'
		def self.for(dc_type)
			case dc_type.to_s
			when "StillImage"
				return IMAGE
			when "Image"
				return IMAGE
			when "Audio"
				return SOUND
			when "Sound"
				return SOUND
			when "Video"
				return VIDEO
			when "MovingImage"
				return VIDEO
			when "Text"
				return TEXT
			when "PageDescription"
				return TEXT
			when "UnstructuredText"
				return TEXT
			when "Email"
				return TEXT
			when "HTML"
				return TEXT
			when "StructuredText"
				return TEXT
			when "Presentation"
				return TEXT
			when "Spreadsheet"
				return TEXT
			else
				return nil
			end	
		end
	end
end