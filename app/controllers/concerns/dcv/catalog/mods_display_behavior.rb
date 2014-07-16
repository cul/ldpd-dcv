module Dcv::Catalog::ModsDisplayBehavior
  extend ActiveSupport::Concern

  def mods

    begin
      obj = ActiveFedora::Base.find(params[:pid])
      render xml: obj.descMetadata.content
    rescue ActiveFedora::ObjectNotFoundError, NoMethodError => e
      render text: 'No MODS record found for this ID.'
    end

  end

end
