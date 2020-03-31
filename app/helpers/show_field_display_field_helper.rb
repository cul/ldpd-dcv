module ShowFieldDisplayFieldHelper
  include FieldDisplayHelpers::ArchivalContext
  include FieldDisplayHelpers::Format
  include FieldDisplayHelpers::LocationUrls
  include FieldDisplayHelpers::Name
  include FieldDisplayHelpers::Note
  include FieldDisplayHelpers::Project
  include FieldDisplayHelpers::Publisher
  include FieldDisplayHelpers::Repository
  include FieldDisplayHelpers::Rights

  def is_excepted_dynamic_field?(field_config, document)
    (field_config.except || []).include? field_config.field
  end

  # return the Blacklight::AbstractRepository in scope
  def doc_repository
    if defined?(:controller)
      controller.repository
    elsif defined?(:repository)
      repository
    else
      Blacklight.default_index
    end
  end

  # return a cache key for the field given the Blacklight::AbstractRepository in scope
  def repository_cache_key(field_name)
    if defined?(:controller) || defined?(:repository)
      core = doc_repository.connection.uri.to_s.split('/')[-1]
      cache_key = "dcv.#{field_name}.#{core}"
    else
      doc_repository = Blacklight.default_index
      cache_key = "dcv.#{field_name}.default"
    end
  end
end
