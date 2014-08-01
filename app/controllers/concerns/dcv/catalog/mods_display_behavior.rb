module Dcv::Catalog::ModsDisplayBehavior
  extend ActiveSupport::Concern

  def mods

    begin
      obj = ActiveFedora::Base.find(params[:id])
      if obj.respond_to?(:descMetadata) && obj.descMetadata.present?
        xml_content = obj.descMetadata.content
        if params[:type] == 'formatted_text'
          xml_content = '<!DOCTYPE html><html><head><title>XML View</title></head><body style="border:1px solid #aaa;padding:0px 10px;"><div style="overflow: auto;">' + CodeRay.scan(xml_content, :xml).div() + '</div></body></html>'
          render text: xml_content
        elsif params[:type] == 'download'
          send_data(xml_content, :type=>"text/xml",:filename => params[:id].gsub(':', '_') + '.xml')
        else
          render xml: xml_content
        end
      else
        render text: 'No MODS record found for this object.'
      end
    rescue ActiveFedora::ObjectNotFoundError
      render text: 'Object not found.'
    end

  end

end
