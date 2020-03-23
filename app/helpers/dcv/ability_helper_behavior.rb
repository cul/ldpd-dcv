module Dcv::AbilityHelperBehavior
  def can_download?(document)
    document = SolrDocument.new(document) unless document.is_a? SolrDocument
    if controller.subsite_config['show_original_file_download']
      can? Ability::ACCESS_ASSET, document
    else
      false
    end
  end
end
