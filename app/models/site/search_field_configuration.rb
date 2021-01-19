class Site::SearchFieldConfiguration
	include ActiveModel::Dirty
	include ActiveModel::Serializers::JSON
	include ActiveModel::Validations
	include ActiveRecord::AttributeAssignment
	include Dcv::Configurators::BaseBlacklightConfigurator

	VALID_TYPES = ['fulltext', 'identifier', 'keyword', 'name', 'title'].freeze
	ATTRIBUTES = [:type, :label]

	define_attribute_methods *ATTRIBUTES
	attr_accessor *ATTRIBUTES
	validates :type, inclusion: { in: VALID_TYPES }

	def default_configuration
		{ type: 'keyword', label: 'All Fields' }
	end

	def initialize(atts = {})
		atts = atts.symbolize_keys
		atts[:label] = atts[:type].titlecase if atts[:type] && atts[:label].blank?
		atts = default_configuration.merge(atts).with_indifferent_access
		assign_attributes(atts)
		clear_changes_information
	end

	def eql?(obj)
		return false unless obj.is_a? ::Site::SearchFieldConfiguration
		attributes.eql?(obj.attributes)
	end

	def attributes
		as_json
	end

	def serializable_hash(opts = {})
		{
			'type' => @type,
			'label' => @label
		}.tap {|v| v.compact! if opts&.fetch(:compact, false)}
	end

	def configure(blacklight_config)
		case @type
		when 'fulltext'
			configure_fulltext_search_field(blacklight_config, label: @label)
		when 'identifier'
			configure_identifier_search_field(blacklight_config, label: @label)
		when 'keyword'
			configure_keyword_search_field(blacklight_config, label: @label)
		when 'name'
			configure_name_search_field(blacklight_config, label: @label)
		when 'title'
			configure_title_search_field(blacklight_config, label: @label)
		else
			false
		end
	end
end