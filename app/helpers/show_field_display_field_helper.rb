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

end
