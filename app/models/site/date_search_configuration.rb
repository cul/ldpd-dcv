class Site::DateSearchConfiguration
	include ActiveModel::Dirty
	include ActiveModel::Serializers::JSON
	include ActiveRecord::AttributeAssignment

	VALID_GRANULARITY_VALUES = ['day', 'year'].freeze
	DEFAULT_ENABLED_CONFIGURATION = { granularity_search: 'year', sidebar_label: 'Date Range' }.freeze

	define_attribute_methods :enabled, :granularity_search, :show_sidebar, :show_timeline, :sidebar_label
	attr_accessor :enabled, :granularity_search, :show_sidebar, :show_timeline, :sidebar_label

	def default_configuration
		{ enabled: false }
	end

	def initialize(atts = {})
		atts = default_configuration.merge(atts.symbolize_keys).with_indifferent_access
		assign_attributes(atts)
		clear_changes_information
	end

	def enabled=(val)
		val = (val.to_s =~ /true/i) ? true : false
		enabled_will_change! unless val == @enabled
		enable! if val
		@enabled = val
	end

	def enable!
		DEFAULT_ENABLED_CONFIGURATION.each do |k, v|
			next if k == :enabled
			curr = send k
			send(:"#{k}=", v.dup) if curr.nil?
		end
	end

	def granularity_search=(val)
		val = nil unless VALID_GRANULARITY_VALUES.include?(val)
		granularity_search_will_change! unless val == @granularity_search
		@granularity_search = val
	end

	def show_sidebar=(val)
		val = (val.to_s =~ /true/i) ? true : false
		show_sidebar_will_change! unless val == @show_sidebar
		@show_sidebar = val
	end

	def show_timeline=(val)
		val = (val.to_s =~ /true/i) ? true : false
		show_timeline_will_change! unless val == @show_timeline
		@show_timeline = val
	end

	def eql?(obj)
		return false unless obj.is_a? ::Site::DateSearchConfiguration
		as_json.eql?(obj.as_json)
	end

	def attributes
		as_json
	end

	def serializable_hash(opts = {})
		{
			'enabled' => @enabled,
			'granularity_search' => @granularity_search,
			'show_sidebar' => @show_sidebar,
			'show_timeline' => @show_timeline,
			'sidebar_label' => @sidebar_label
		}.tap {|v| v.compact! if opts&.fetch(:compact, false)}
	end
end