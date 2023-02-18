module Dcv::Catalog::ModsDisplayBehavior
  extend ActiveSupport::Concern

  def mods
    begin
      ds_content = Cul::Hydra::Fedora.ds_for_opts(pid: params[:id], dsid: 'descMetadata')&.content
      if ds_content.present?
        xml_content = Nokogiri::XML(ds_content) {|config| config.default_xml.noblanks}.to_xml(:indent => 2)
        if params[:type] == 'formatted_text'
          html_content = '<div style="border:1px solid #aaa;padding:0px 10px;overflow: auto;">' + CodeRay.scan(xml_content, :xml).div() + '</div>'
          render html: html_content.html_safe
        elsif params[:type] == 'download'
          send_data(xml_content, :type=>"text/xml",:filename => params[:id].gsub(':', '_') + '.xml')
        else
          render xml: xml_content
        end
      else
        render plain: 'No MODS record found for this object.'
      end
    rescue ActiveFedora::ObjectNotFoundError
      render plain: 'Object not found.'
    end
  end
end
