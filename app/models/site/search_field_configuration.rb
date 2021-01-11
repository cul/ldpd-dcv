class Site::SearchFieldConfiguration
	include ActiveModel::Dirty
	include ActiveModel::Serializers::JSON
	include ActiveModel::Validations
	include ActiveRecord::AttributeAssignment

	VALID_TYPES = ['fulltext', 'identifier', 'keyword', 'name', 'title'].freeze
	ATTRIBUTES = [:type, :label]

	define_attribute_methods *ATTRIBUTES
	attr_accessor *ATTRIBUTES
	validates :type, inclusion: { in: VALID_TYPES }

	def default_configuration
		{ type: 'keyword', label: 'All Fields' }
	end

	def initialize(atts = {})
		atts = default_configuration.merge(atts.symbolize_keys).with_indifferent_access
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
end