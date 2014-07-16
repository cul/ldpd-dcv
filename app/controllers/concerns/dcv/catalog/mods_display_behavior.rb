module Dcv::Catalog::ModsDisplayBehavior
  extend ActiveSupport::Concern

  def mods

    begin
      obj = ActiveFedora::Base.find(params[:pid])
      if obj.respond_to?(:descMetadata) && obj.descMetadata.present?
        render xml: obj.descMetadata.content
      else
        render text: 'No MODS record found for this object.'
      end
    rescue ActiveFedora::ObjectNotFoundError
      render text: 'Object not found.'
    end

  end

end
