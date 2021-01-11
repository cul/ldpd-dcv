class Site::MapConfiguration
	include ActiveModel::Dirty
	include ActiveModel::Serializers::JSON
	include ActiveRecord::AttributeAssignment

	DEFAULT_ENABLED_CONFIGURATION = { granularity_data: 'city', granularity_search: 'country', show_items: true, show_sidebar: false, default_lat: 0.0, default_long: 0.0 }.freeze
	VALID_GRANULARITY_VALUES = { 'city' => 11, 'country' => 5, 'global' => 1, 'street' => 17 }.freeze

	define_attribute_methods :default_lat, :default_long, :enabled, :granularity_data, :granularity_search, :show_items, :show_sidebar
	attr_accessor :default_lat, :default_long, :enabled, :granularity_data, :granularity_search, :show_items, :show_sidebar

	def default_configuration
		{ enabled: false }
	end

	def initialize(atts = {})
		atts = default_configuration.merge(atts.symbolize_keys).with_indifferent_access
		assign_attributes(atts)
		clear_changes_information
	end

	def default_lat=(val)
		val = val.to_f unless val.nil?
		default_lat_will_change! unless val == @default_lat
		@default_lat = val
	end

	def default_long=(val)
		val = val.to_f unless val.nil?
		default_long_will_change! unless val == @default_long
		@default_long = val
	end

	def enabled=(val)
		val = (val.to_s =~ /true/i) ? true : false
		enabled_will_change! unless val == @enabled
		@enabled = val
		enable! if val
		@enabled
	end

	def enable!
		DEFAULT_ENABLED_CONFIGURATION.each do |k, v|
			next if k == :enabled
			curr = send k
			send(:"#{k}=", v.dup) if curr.nil?
		end
	end

	def granularity_data=(val)
		val = nil unless VALID_GRANULARITY_VALUES.include?(val)
		granularity_data_will_change! unless val == @granularity_data
		@granularity_data = val
	end

	def granularity_search=(val)
		val = nil unless VALID_GRANULARITY_VALUES.include?(val)
		granularity_search_will_change! unless val == @granularity_search
		@granularity_search = val
	end

	def default_zoom
		VALID_GRANULARITY_VALUES[@granularity_search]
	end

	def max_zoom
		VALID_GRANULARITY_VALUES[@granularity_data]
	end

	def show_sidebar=(val)
		val = (val.to_s =~ /true/i) ? true : false
		show_sidebar_will_change! unless val == @show_sidebar
		@show_sidebar = val
	end

	def eql?(obj)
		return false unless obj.is_a? ::Site::MapConfiguration
		as_json.eql?(obj.as_json)
	end

	def attributes
		as_json
	end

	def serializable_hash(opts = {})
		{
			'default_lat' => @default_lat,
			'default_long' => @default_long,
			'enabled' => @enabled,
			'granularity_data' => @granularity_data,
			'granularity_search' => @granularity_search,
			'show_items' => @show_items,
			'show_sidebar' => @show_sidebar
		}.tap {|v| v.compact! if opts&.fetch(:compact, false)}
	end
end