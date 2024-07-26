module Dcv
	class FieldPresenter < Blacklight::FieldPresenter
		# duplicated from Blacklight::FieldPresenter to override use of
		# allow use of a helper method for label
		def label(context = 'index', **options)
			if field_config.label.is_a? Symbol
				field_opts = { field: field_config.field, context: context }
				view_context.send(field_config.label, document, options.merge(field_opts))
			else
				super
			end
		end
		def pipeline_steps
			upstream_operations = Blacklight::Rendering::Pipeline.operations.dup
			upstream_operations.index(Blacklight::Rendering::LinkToFacet)&.tap { |ix| upstream_operations[ix] = Rendering::LinkToFacet }
			(options[:steps] || field_config[:steps] || upstream_operations) - except_operations
		end
	end
end
