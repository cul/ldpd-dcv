class ScopeFilter < ActiveRecord::Base
	VALID_TYPES = ['publisher', 'project', 'project_key', 'collection', 'collection_key', 'repository_code'].freeze
	belongs_to :scopeable, polymorphic: true, touch: true
	validates :filter_type, inclusion: { in: VALID_TYPES }
end