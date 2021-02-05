module Dcv::AbilityHelperBehavior
  def can_download?(document)
    document = SolrDocument.new(document) unless document.is_a? SolrDocument
    current_configuration = controller.load_subsite&.search_configuration
    if current_configuration && current_configuration.display_options.show_original_file_download
      can? Ability::ACCESS_ASSET, document
    else
      false
    end
  end
end
