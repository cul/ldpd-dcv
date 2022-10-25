require 'active-fedora'
class Cul::Hydra::Datastreams::NokogiriDatastream < ::ActiveFedora::Datastream
  define_attribute_methods :ng_xml

  include ::ActiveFedora::Datastreams::NokogiriDatastreams    

  def ng_xml_will_change!
    mutations_from_database.force_change(:ng_xml)
  end
end