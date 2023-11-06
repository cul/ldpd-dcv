class Dcv::Solr::DocumentAdapter::ActiveFedora::GenericResource
  class << self
    # Create a new adapter object
    # @param obj [ActiveFedora::Base]
    # @return [Dcv::Solr::DocumentAdapter::ActiveFedora::GenericResource]
    def IiifData obj
      Dcv::Solr::DocumentAdapter::ActiveFedora::GenericResource::IiifData.new(obj)
    end
  end

  class IiifData < Dcv::Solr::DocumentAdapter::ActiveFedora

    def to_solr(solr_doc={}, opts={})
      return solr_doc unless obj.is_a?(::ActiveFedora::Base) && matches_any_cmodel?(["info:fedora/ldpd:GenericResource"])
      iiif_data_url = Dcv::Utils::CdnUtils.info_url({ id: obj.pid })
      iiif_data = fetch_iiif_data(iiif_data_url)
      solr_doc['image_width_isi'] = iiif_data['width'] if iiif_data['width']
      solr_doc['image_height_isi'] = iiif_data['height'] if iiif_data['height']
      solr_doc
    end

    def fetch_iiif_data(iiif_url)
      response = Faraday.get(iiif_url)
      if response.status == 200
        JSON.load(response.body)
      else
        {}
      end
    rescue Faraday::ConnectionFailed
      {}
    end
  end
end