module Dcv::Components
  module ActiveFedoraDocumentBehavior
    def active_fedora_model(document = @document)
      document[:active_fedora_model_ssi] if document
    end

    def has_datastream?(dsid, document = @document)
      document.fetch(:datastreams_ssim, []).include?(dsid) if document
    end
  end
end