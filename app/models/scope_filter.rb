class ScopeFilter < ApplicationRecord
	FIELDS_FOR_FILTER_TYPES = {
		'publisher'       => 'publisher_ssim',
		'project'         => 'lib_project_short_ssim',
		'project_key'     => 'project_key_ssim',
		'collection'      => 'lib_collection_sim',
		'collection_key'  => 'collection_key_ssim',
		'repository_code' => 'lib_repo_code_ssim'
	}.freeze
	VALID_TYPES = FIELDS_FOR_FILTER_TYPES.keys.freeze
	belongs_to :scopeable, polymorphic: true, touch: true
	validates :filter_type, inclusion: { in: VALID_TYPES }
	def solr_field
		FIELDS_FOR_FILTER_TYPES[self.filter_type]
	end
end