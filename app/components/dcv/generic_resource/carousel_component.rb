# frozen_string_literal: true

module Dcv::GenericResource
  class CarouselComponent < ViewComponent::Base
    include Dcv::Components::ActiveFedoraDocumentBehavior
    include Dcv::Components::ChildViewerBehavior

    delegate :can_access_asset?, :is_publicly_available_asset?, to: :helpers

    def initialize(document:, parent_title: nil, **_opts)
      super
      @document = document
      @structured_children = [document]
      @parent_title = parent_title
    end

    def before_render
      @local_downloads = is_publicly_available_asset?(@document)
    end

    def fake_child
      @fake_child ||= begin
        doc_pid = @document[:fedora_pid_uri_ssi].split('/')[-1]
        dc_type = @document[:dc_type_ssm]&.first
        @document.to_h.merge({id: doc_pid, pid: doc_pid, dc_type: dc_type})
      end
    end
  end
end
