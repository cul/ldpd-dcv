class Site::DisplayOptions
	include ActiveModel::Dirty
	include ActiveModel::Serializers::JSON
	include ActiveRecord::AttributeAssignment
	include Site::ConfigurationValues

	define_attribute_methods :default_search_mode, :show_csv_results, :show_original_file_download, :show_other_sources, :grid_field_types
	attr_accessor :default_search_mode, :show_csv_results, :show_original_file_download, :show_other_sources, :grid_field_types

	VALID_SEARCH_MODES = %w(grid list).freeze
	VALID_GRID_FIELD_TYPES = %w(format name project).freeze

	def default_configuration
		{
			default_search_mode: 'grid', show_csv_results: false, show_original_file_download: false,
			show_other_sources: false, grid_field_types: ['name'] }
	end

	def initialize(atts = {})
		atts = default_configuration.merge(atts.symbolize_keys).with_indifferent_access
		correct_deprecated_att_names(atts)
		assign_attributes(atts)
		clear_changes_information
	end

	# deletable after staging data is corrected for DLC-1143
    def correct_deprecated_att_names(atts)
		# deletable after staging data is corrected
		renamed_tombstone_fields = atts.delete(:tombstone_fields)
		atts[:grid_field_types] = renamed_tombstone_fields if renamed_tombstone_fields.present?
    end

	def default_search_mode=(val)
		@default_search_mode = VALID_SEARCH_MODES.include?(val) ? val : 'grid'
	end

	def grid_field_types=(vals)
		@grid_field_types = Array(vals).map(&:to_s).map(&:downcase).select { |v| VALID_GRID_FIELD_TYPES.include?(v) }
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
			'show_other_sources' => @show_other_sources,
			'grid_field_types' => @grid_field_types || []
		}.tap {|v| v.compact! if opts&.fetch(:compact, false)}
	end
end