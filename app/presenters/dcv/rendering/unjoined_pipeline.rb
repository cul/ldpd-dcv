module Dcv
	module Rendering
		# The field rendering pipeline
		class UnjoinedPipeline < ::Blacklight::Rendering::Pipeline
			# The ordered list of pipeline operations, identical to Blacklight without Join step
			self.operations = [
				::Blacklight::Rendering::HelperMethod,
				::Blacklight::Rendering::LinkToFacet,
				::Blacklight::Rendering::Microdata
			]
			def render
				first, *rest = *stack
				first.new(values, config, document, context, options, rest).render
			end
			def stack
				operations + [::Blacklight::Rendering::Terminator]
			end
		end
	end
end
