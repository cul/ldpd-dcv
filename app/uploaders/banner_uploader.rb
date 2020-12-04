class BannerUploader < CarrierWave::Uploader::Base
	storage :file

	# Only allow png
	def extension_whitelist
		%w(png)
	end

	# Override stored filename
	def filename
		"signature-banner.png"
	end

	def move_to_store
		true
	end

	def store_dir
		File.join(Rails.root, "public/images/sites/#{model.slug}")
	end
end