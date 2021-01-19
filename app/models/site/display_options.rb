class Site::DisplayOptions
	include ActiveModel::Dirty
	include ActiveModel::Serializers::JSON
	include ActiveRecord::AttributeAssignment
	include Site::ConfigurationValues

	define_attribute_methods :default_search_mode, :show_csv_results, :show_original_file_download, :show_other_sources
	attr_accessor :default_search_mode, :show_csv_results, :show_original_file_download, :show_other_sources

	VALID_SEARCH_MODES = ['grid', 'list'].freeze

	def default_configuration
		{ default_search_mode: 'grid', show_csv_results: false, show_original_file_download: false, show_other_sources: false }
	end

	def initialize(atts = {})
		atts = default_configuration.merge(atts.symbolize_keys).with_indifferent_access
		assign_attributes(atts)
		clear_changes_information
	end

	def default_search_mode=(val)
		@default_search_mode = VALID_SEARCH_MODES.include?(val) ? val : 'grid'
	end

	def show_csv_results=(val)
		val = boolean_or_nil(val)
		show_csv_results_will_change! unless val == @show_csv_results
		@show_csv_results = val
	end

	def show_original_file_download=(val)
		val = boolean_or_nil(val)
		show_original_file_download_will_change! unless val == @show_original_file_download
		@show_original_file_download = val
	end

	def show_other_sources=(val)
		val = boolean_or_nil(val)
		show_other_sources_will_change! unless val == @show_other_sources
		@show_other_sources = val
	end

	def eql?(obj)
		return false unless obj.is_a? ::Site::DisplayOptions
		as_json.eql?(obj.as_json)
	end

	def attributes
		as_json
	end

	def serializable_hash(opts = {})
		{
			'default_search_mode' => @default_search_mode,
			'show_csv_results' => @show_csv_results,
			'show_original_file_download' => @show_original_file_download,
			'show_other_sources' => @show_other_sources
		}.tap {|v| v.compact! if opts&.fetch(:compact, false)}
	end
end