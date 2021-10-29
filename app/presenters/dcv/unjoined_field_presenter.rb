module Dcv
	class UnjoinedFieldPresenter < Blacklight::FieldPresenter
		# duplicated from Blacklight::FieldPresenter to override use of
		# Blacklight::Rendering::Pipeline with Dcv::Rendering::UnjoinedPipeline
		def render
			if options[:value]
				# This prevents helper methods from drawing.
				config = ::Blacklight::Configuration::NullField.new(field_config.to_h.except(:helper_method))
				values = Array.wrap(options[:value])
			else
				config = field_config
				values = retrieve_values
			end
			Rendering::UnjoinedPipeline.render(values, config, document, view_context, options)
		end
	end
end
