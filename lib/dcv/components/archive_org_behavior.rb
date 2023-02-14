module Dcv::Components
  module ArchiveOrgBehavior
    def solr_children_adapter
      @children_adapter ||= Dcv::Solr::ChildrenAdapter.new(controller, helpers, "title_ssm")
    end
    def archive_org_identifiers_as_children
      @archive_org_identifiers ||= solr_children_adapter.from_archive_org_identifiers(@document)
    end
  end
end