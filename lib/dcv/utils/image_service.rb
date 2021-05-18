module Dcv::Utils::ImageService
  class Base
    def initialize(id, opts = {})
      @id = id
      @routes = opts[:routes]
    end
    def details_url
      nil
    end
    def download_url
      nil
    end
    def poster_url
      nil
    end
    def thumbnail_url
      nil
    end
    def zoom_url(opts = {})
      nil
    end
  end

  class ArchiveOrgImages < Base
    def details_url
      "https://archive.org/details/#{archive_org_id}"
    end
    def download_url
      "https://archive.org/download/#{archive_org_id}/#{archive_org_id}.pdf"
    end
    def poster_url
      "https://archive.org/download/#{@id}/page/cover_medium.jpg"
    end
    def thumbnail_url
      "https://archive.org/services/img/#{@id}"
    end
    def zoom_url(opts = {})
      "https://archive.org/stream/#{archive_org_id}?ui=full&showNavbar=false"
    end
  end

  class IiifImages < Base
    def thumbnail_url
      Dcv::Utils::CdnUtils.asset_url(id: @id, size: 256, type: 'featured', format: 'jpg')
    end
    def poster_url
      Dcv::Utils::CdnUtils.asset_url(id: @id, size: 768, type: 'full', format: 'jpg')
    end
    def zoom_url(opts = {})
    end
  end

  class PlaceHolderImages < Base
    def initialize(id, opts)
      super
      @formats = Array(opts[:formats]).compact.map(&:to_s)
      @has_external_content = opts[:has_external_content]
      @routes = opts[:routes]
    end
    def thumbnail_url
      placeholder_format = (['books', 'maps'] & @formats).first&.singularize
      if placeholder_format
        if @has_external_content
          @routes.image_url("#{placeholder_format}-placeholder-e.png")
        else
          @routes.image_url("#{placeholder_format}-placeholder.png")
        end
      else
        @routes.image_url("thumbtack-fa-placeholder.png")
      end
    end
  end

  def self.schema_image_for_document(document)
    schema_image = Array(document['schema_image_ssim']).first
    # non-site behavior
    schema_image = document['representative_generic_resource_pid_ssi'] if schema_image.blank?
    schema_image.present? ? schema_image.split('/')[-1] : nil
  end

  def self.for(document, routes = nil)
    solr_doc =  document.is_a?(SolrDocument) ? document : SolrDocument.new(document)
    opts = { routes: routes }
    return ArchiveOrgImages.new(solr_doc.archive_org_identifier, opts) if solr_doc.archive_org_identifier
    schema_image = schema_image_for_document(solr_doc)
    return IiifImages.new(schema_image, opts) if schema_image
    if solr_doc['cul_number_of_members_isi'] == 0
      opts[:formats] = solr_doc.fetch('lib_format_ssm', [])
      opts[:has_external_content] = solr_doc['lib_non_item_in_context_url_ssm'].present?
      opts[:routes] = routes
      return PlaceHolderImages.new(solr_doc.id, opts)
    end
    IiifImages.new(solr_doc.id)
  end
end
