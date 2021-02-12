class Site::Permissions
	include ActiveModel::Dirty
	include ActiveModel::Serializers::JSON
	include ActiveRecord::AttributeAssignment
	include Site::ConfigurationValues

	ATTRIBUTES = [:remote_roles, :remote_ids, :locations].freeze

	define_attribute_methods *ATTRIBUTES
	attr_accessor *ATTRIBUTES

	def default_configuration
		{ remote_roles: [], remote_ids: [], locations: [] }
	end

	def initialize(atts = {})
		@is_new = atts.blank?
		atts = default_configuration.merge(atts.to_h.symbolize_keys).with_indifferent_access
		atts.keep_if {|k,v| ATTRIBUTES.include?(k.to_sym)}
		assign_attributes(atts)
		clear_changes_information
	end

	def remote_roles=(val)
		val = Array(val).compact.map(&:to_s).freeze
		remote_roles_will_change! unless val == @remote_roles
		@remote_roles = val
	end

	def remote_ids=(val)
		val = Array(val).compact.map(&:to_s).freeze
		remote_ids_will_change! unless val == @remote_ids
		@remote_ids = val
	end

	def locations=(val)
		val = Array(val).compact.map(&:to_s).freeze
		locations_will_change! unless val == @locations
		@locations = val
	end

	def new_record?
		@is_new
	end

	def eql?(obj)
		return false unless obj.is_a? ::Site::Permissions
		as_json.eql?(obj.as_json)
	end

	def attributes
		as_json
	end

	def serializable_hash(opts = {})
		{
			'remote_ids' => @remote_ids || [],
			'remote_roles' => @remote_roles || [],
			'locations' => @locations || []
		}.tap {|v| v.compact! if opts&.fetch(:compact, false)}
	end

	class Type <  ActiveRecord::Type::Value
		include ActiveRecord::Type::Mutable
		def type
			Site::Permissions
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
			when Site::Permissions
				src
			when Hash
				Site::Permissions.new(src)
			when Proc
				cast_value(src.call)
			else
				Site::Permissions.new(JSON.load(src))
			end
		end
	end
end