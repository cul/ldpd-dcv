class Site::SearchConfiguration
	include ActiveModel::Dirty
	include ActiveModel::Serializers::JSON
	include ActiveRecord::AttributeAssignment

	define_attribute_methods :date_search_configuration, :display_options, :facets, :map_configuration, :search_fields
	attr_accessor :date_search_configuration, :display_options, :facets, :map_configuration, :search_fields

	def default_configuration
		{
			date_search_configuration: {}, facets: [], map_configuration: {}, display_options: {},
			search_fields: [Site::SearchFieldConfiguration.new]
		}
	end

	def initialize(atts = {})
		assign_attributes(default_configuration.merge(atts.to_h.symbolize_keys))
	end

	def serializable_hash(opts = {})
		{
			'date_search_configuration' => @date_search_configuration&.as_json(opts) || {},
			'display_options' => @display_options&.as_json(opts) || {},
			'facets' => @facets&.map {|v| v.as_json(opts) } || [],
			'map_configuration' => @map_configuration&.as_json(opts) || {},
			'search_fields' => @search_fields&.map {|v| v.as_json(opts) } || []
		}.tap {|v| v.compact! if opts&.fetch(:compact, false)}
	end

	def attributes
		as_json
	end

	def date_search_configuration=(val)
		@date_search_configuration = val.is_a?(Site::DateSearchConfiguration) ? val : Site::DateSearchConfiguration.new(val)
	end

	def display_options=(val)
		@display_options = val.is_a?(Site::DisplayOptions) ? val : Site::DisplayOptions.new(val)
	end

	def facets=(vals)
		@facets = Array(vals).map { |val| val.is_a?(Site::FacetConfiguration) ? val : Site::FacetConfiguration.new(val) }.freeze
	end

	def map_configuration=(val)
		@map_configuration = val.is_a?(Site::MapConfiguration) ? val : Site::MapConfiguration.new(val)
	end

	def search_fields=(vals)
		@search_fields = Array(vals).map { |val| val.is_a?(Site::SearchFieldConfiguration) ? val : Site::SearchFieldConfiguration.new(val) }.freeze
	end

	def empty?
		false
	end

	class Type <  ActiveRecord::Type::Value
		include ActiveRecord::Type::Mutable
		def type
			Site::SearchConfiguration
		end

		def type_cast_for_database(obj)
			JSON.dump(obj.as_json(compact: true))
		end

		# Override as base class will return nil (this type should not be nil) 
		def type_cast_from_database(obj)
			cast_value(obj)
		end

		def cast_value(src)
			case src
			when Site::SearchConfiguration
				src
			when Hash
				Site::SearchConfiguration.new(src)
			when Proc
				cast_value(src.call)
			else
				Site::SearchConfiguration.new(JSON.load(src))
			end
		end
	end
end