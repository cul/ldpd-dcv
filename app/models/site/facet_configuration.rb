class Site::FacetConfiguration
	include ActiveModel::Dirty
	include ActiveModel::Serializers::JSON
	include ActiveRecord::AttributeAssignment
	include Site::ConfigurationValues

	VALID_VALUE_TRANSFORMS = ['capitalize', 'singularize', 'translate'].freeze
	VALID_SORTS = ['index', 'count'].freeze
	ATTRIBUTES = [:exclusions, :field_name, :label, :limit, :pivot, :sort, :value_map, :value_transforms].freeze

	define_attribute_methods *ATTRIBUTES
	attr_accessor *ATTRIBUTES

	def default_configuration
		{ limit: 10, sort: 'index', value_transforms: [] }
	end

	def initialize(atts = {})
		@is_new = atts.blank?
		atts = default_configuration.merge(atts.symbolize_keys).with_indifferent_access
		assign_attributes(atts)
		clear_changes_information
	end

	def exclusions=(val)
		val = Array(val).select { |v| v.present? }
		exclusions_will_change! unless val == @exclusions
		@exclusions = val
	end

	def limit=(val)
		val = int_or_nil(val)
		limit_will_change! unless val == @limit
		@limit = val		
	end

	def pivot=(val)
		val = val.nil? ? val : clean_and_freeze_array(val)
		pivot_will_change! unless val == @pivot
		@pivot = val
	end

	# form UI convenience method
	def facet_fields_form_value
		(pivot || []).dup.unshift(field_name.to_s).join(',')
	end

	# form UI convenience method
	def facet_fields_form_value=(val)
		vals = val.split(/[\s,]+/)
		self.field_name = vals[0]
		self.pivot = vals.length > 1 ? vals[1..-1] : nil
	end

	def value_transforms=(val)
		val = clean_and_freeze_validated_array(val, VALID_VALUE_TRANSFORMS)
		value_transforms_will_change! unless val == @value_transforms
		@value_transforms = val
	end

	def new_record?
		@is_new
	end

	def eql?(obj)
		return false unless obj.is_a? ::Site::FacetConfiguration
		as_json.eql?(obj.as_json)
	end

	def attributes
		as_json
	end

	def serializable_hash(opts = {})
		{
			'exclusions' => @exclusions,
			'field_name' => @field_name,
			'label' => @label,
			'limit' => @limit,
			'pivot' => @pivot,
			'sort' => @sort,
			'value_map' => @value_map,
			'value_transforms' => @value_transforms || []
		}.tap {|v| v.compact! if opts&.fetch(:compact, false)}
	end

	def configure(blacklight_config)
		return false if @field_name.blank? || blacklight_config.facet_fields[@field_name]
		opts = {label: @label, limit: @limit, sort: @sort}
		if @exclusions.present?
			opts[:cul_custom_value_hide] = Array(@exclusions)
		end
		if @value_transforms.present?
			opts[:cul_custom_value_transforms] = Array(@value_transforms)
		end
		if @value_map.present?
			opts[:translation] = @value_map
		end
		if @pivot.present?
			opts[:pivot] = @pivot.dup.unshift(@field_name)
			# propagate the sort configuration to the pivoted facets
			@pivot.each { |pf| blacklight_config.default_solr_params[:"f.#{pf}.facet.sort"] ||= @sort }
		end
		blacklight_config.add_facet_field @field_name, opts
	end
end