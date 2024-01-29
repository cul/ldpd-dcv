module Dcv::CdnHelper

  def zoomable_image_exists_for_resource?(pid)
    uri = URI.parse(get_iiif_zoom_info_url(id: pid))
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    return response.code == '200' && JSON.parse(response.body)['sizes'].present?
  end

  def get_manifest_url(document, collection: nil, **options)
    doi = document['ezid_doi_ssim']&.first
    return nil unless doi
    doi = doi.sub(/^doi\:/,'') || doi
    registrant, doi = doi.split('/')
    return iiif_collection_url(collection_registrant: registrant, collection_doi: doi) if collection
    iiif_manifest_url(options.merge(version: 3, manifest_registrant: registrant, manifest_doi: doi))
  end

  def get_asset_url(conditions)
    Dcv::Utils::CdnUtils.asset_url(conditions)
  end

  def get_resolved_asset_url(conditions)
    resolved_id = identifier_to_pid(conditions[:id], conditions[:pid])
    Dcv::Utils::CdnUtils.asset_url(conditions.merge(id: resolved_id))
  end

  def get_asset_info_url(conditions)
    get_iiif_zoom_info_url(conditions)
  end

  def get_resolved_asset_info_url(conditions)
    get_resolved_iiif_zoom_info_url(conditions)
  end

  def get_iiif_zoom_info_url(conditions)
    Dcv::Utils::CdnUtils.info_url(conditions)
  end

  def get_resolved_iiif_zoom_info_url(conditions)
    resolved_id = identifier_to_pid(conditions[:id], conditions[:pid])
    Dcv::Utils::CdnUtils.info_url(conditions.merge(id: resolved_id))
  end

  def archive_org_id_for_document(document)
    document = SolrDocument.new(document) unless document.is_a? SolrDocument
    document.archive_org_identifier
  end

  # if archive.org resource, build an appropriate thumb URL, else nil
  def get_archive_org_thumbnail_url(document)
    if archive_org_id = archive_org_id_for_document(document)
      return "https://archive.org/services/img/#{archive_org_id}"
    end
  end

  # if archive.org resource, build an appropriate thumb URL, else nil
  def get_archive_org_poster_url(document)
    if archive_org_id = archive_org_id_for_document(document)
      return "https://archive.org/download/#{archive_org_id}/page/cover_medium.jpg"
    end
  end

  def get_archive_org_details_url(document)
    if archive_org_id = archive_org_id_for_document(document)
      return "https://archive.org/details/#{archive_org_id}"
    end
  end

  def get_archive_org_download_url(document)
    if archive_org_id = archive_org_id_for_document(document)
      return "https://archive.org/download/#{archive_org_id}/#{archive_org_id}.pdf"
    end
  end

  def thumbnail_url(document, options = {})
    if (url = get_archive_org_thumbnail_url(document))
      return url
    end
    size = options.fetch(:size, 256)
    schema_image = Array(document['schema_image_ssim']).first
    # non-site behavior
    schema_image = document['representative_generic_resource_pid_ssi'] if schema_image.blank?

    if schema_image.present?
      Dcv::Utils::CdnUtils.asset_url(id: schema_image.split('/')[-1], size: size, type: 'featured', format: 'jpg')
    elsif document[:cul_number_of_members_isi] == 0
      placeholder_format = (['books', 'maps'] & document.fetch('lib_format_ssm', [])).first&.singularize
      if placeholder_format
        if document['lib_non_item_in_context_url_ssm'].present?
          image_url("#{placeholder_format}-placeholder-e.png")
        else
          image_url("#{placeholder_format}-placeholder.png")
        end
      else
        image_url("thumbtack-fa-placeholder.png")
      end
    else # fall back to whatever the item does from image server
      Dcv::Utils::CdnUtils.asset_url(id: document.id, size: size, type: 'featured', format: 'jpg')
    end
  end

  def poster_url(item, opts = {})
    if (url = get_archive_org_poster_url(item))
      return url
    end
    schema_image = Array(item['schema_image_ssim']).first

    id = schema_image ? schema_image.split('/')[-1] : nil
    id ||= identifier_to_pid(item[:id], item[:pid])
    opts = { size: 768, type: 'full', format: 'jpg' }.merge(opts)
    Dcv::Utils::CdnUtils.asset_url(opts.merge(id: id))
  end

  def thumbnail_for_doc(document, image_options = {})
    image_tag thumbnail_url(document), image_options
  end

  # return an appropriate details path for the item and asset/child
  # opts should include a layout name 'layout' and optionally an index 'ix'
  def zoom_url_for_doc(item, asset = {}, opts = {})
    default_opts = {
      layout: 'dcv', initial_page: 0, title: true, id: nil
    }
    opts = opts.reverse_merge(default_opts)
    opts[:id] = asset[:dc_type] == 'StillImage' ? item[:id] : asset[:pid]
    iframe_url_for_document(item) || details_path(opts)
  end

  def thumbnail_for_site(site)
    id = site.image_uri ? site.image_uri.split('/')[-1] : nil
    if id
      get_asset_url(id: id, size: 256, type: 'featured', format: 'jpg')
    else
      asset_path('dcv/columbia_crown_outline.png')
    end
  end

  def thumbnail_placeholder(document, image_options={})
    image_tag image_url('file-placeholder.png')
  end
end
