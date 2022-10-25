class Cul::Hydra::Datastreams::ModsDocument < Cul::Hydra::Datastreams::NokogiriDatastream

  def self.default_attributes
    super.merge(:controlGroup => 'M', :mimeType => 'text/xml')
  end

  def self.xml_template
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.mods(:version=>"3.4",
         "xmlns"=>"http://www.loc.gov/mods/v3",
         "xmlns:xlink"=>"http://www.w3.org/1999/xlink",
         "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance"){
      }
    end
    builder.doc.encoding = 'UTF-8'
    # for some reason, this is the only way to get an equivalent nokogiri root node; the attribute can't be in the original builder call
    builder.doc.root["xsi:schemaLocation"] = 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-4.xsd'
    return builder.doc
  end
end
