class WatermarkUploader < CarrierWave::Uploader::Base
	storage :file

	# Only allow svg
	def extension_whitelist
		%w(svg)
	end

	# Override stored filename
	def filename
		"signature.svg"
	end

	def move_to_store
		true
	end

	def store_dir
		File.join(Rails.root, "public/images/sites/#{model.slug}")
	end
end