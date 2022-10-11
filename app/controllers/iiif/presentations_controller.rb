require 'json'
class Iiif::PresentationsController < ApplicationController
  include Dcv::Sites::SearchableController
  include Dcv::CatalogIncludes
  include Dcv::SolrHelper
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  configure_blacklight do |config|
    Dcv::Configurators::DcvBlacklightConfigurator.configure(config)
  end

  layout false

  self.search_service_class = Dcv::SearchService

  def child_service
    @children_adapter ||= Dcv::Solr::ChildrenAdapter.new(self, self, "title_ssm")
  end

  def show
    redirect_to iiif_manifest_url(params), status: 302
  end

  def fetch_by_doi_opts(query_opts = {})
    # these can be mutated during processing, so must be a new object and not a constant
    default_opts = { q: "{!raw f=ezid_doi_ssim v=$id}", fq: ["object_state_ssi:A"] }
    default_opts.merge(query_opts)
  end

  def fetch_by_doi(doi, query_opts = {}, force_refresh = false, expiry = 30.seconds)
    fetch_from_cache(doi, fetch_by_doi_opts(query_opts), expiry, force_refresh)
  end


  def manifest
    cors_headers

    doi = "#{params[:manifest_registrant]}/#{params[:manifest_doi]}"
    manifest_params = select_params(:manifest_registrant, :manifest_doi)
    collection_params = select_params(:collection_registrant, :collection_doi)
    if collection_params.length == 2
      collection_doi_param = "doi:#{params[:collection_registrant]}/#{params[:collection_doi]}"
      collection_document = fetch_by_doi collection_doi_param
      local_params = {}
      local_params[:fl] = "*,proxy:[subquery]"
      local_params[:"proxy.q"] = "{!terms f=proxyFor_ssi v=$row.dc_identifier_ssim}"
      local_params[:"proxy.fq"] = "proxyIn_ssi:\"#{collection_document['fedora_pid_uri_ssi']}\""
      @response, @document = fetch("doi:#{doi}", fetch_by_doi_opts(local_params))
      proxy_source = @document['proxy']['docs']&.first
      proxy_doc = SolrDocument.new(proxy_source) if proxy_source
    else
      @response, @document = fetch("doi:#{doi}", fetch_by_doi_opts)
    end
    container = manifest_container(collection_document, proxy_doc)
    if container
      manifest_params.merge!(collection_params)
      manifest_id = iiif_collected_manifest_url(manifest_params)
      part_of = [container]
    else
      manifest_id = iiif_manifest_url(manifest_params)
      part_of = nil
    end
    manifest = Iiif::Manifest.new(manifest_id, @document, child_service, self, part_of)
    render json: manifest.as_json(include: [:items, :metadata, :context]).compact
  end

  # return a Iiif::Collection is collection params are present and manifest is in collection
  def manifest_container(collection_document, proxy_doc)
    return unless collection_document.present? && proxy_doc.present?
    proxy_path = proxy_doc.id.split("/structMetadata/")[1]
    proxy_path = proxy_path.split('/')[0...-1].join('/') if proxy_path
    collection_params = select_params(:collection_registrant, :collection_doi)
    collection_params[:proxy_path] = CGI.unescape(proxy_path) if proxy_path.present?
    collection_id = iiif_collection_url(collection_params)
    Iiif::Collection.new(collection_id, collection_document, child_service, self)
  end

  def range
    #TODO: Support dereferenceable range constructs
  end

  def canvas
    cors_headers
    manifest_doi_param = "#{params[:manifest_registrant]}/#{params[:manifest_doi]}"
    manifest_doc = fetch_by_doi "doi:#{manifest_doi_param}"
    manifest_params = select_params(:manifest_registrant, :manifest_doi)
    manifest_id = iiif_manifest_url(manifest_params)
    manifest = Iiif::Manifest.new(manifest_id, manifest_doc, child_service, self, nil)
    canvas_doi_param = "#{params[:registrant]}/#{params[:doi]}"
    if canvas_doi_param == manifest_doi_param
      canvas_doc = manifest_doc
      label = manifest.label[:en]
    else
      canvas_doc = fetch_by_doi "doi:#{canvas_doi_param}"
      label = nil
    end
    canvas = manifest.canvas_for(canvas_doc, manifest.route_helper, manifest.routing_opts, label)
    render json: canvas.as_json(include: [:context]).compact
  end

  def annotation_page
    #TODO: Support dereferenceable annotation constructs
  end

  def annotation
    #TODO: Support dereferenceable annotation constructs
  end

  def collection
    cors_headers
    #TODO: Support collections
    # look up the aggregate document (should be a collection)
    doi = "#{params[:collection_registrant]}/#{params[:collection_doi]}"
    # proxy path is present, worth caching top-level doc as may be navigating hierarchy
    if params[:proxy_path].present?
      @document =  fetch_by_doi "doi:#{doi}"
    else
      @document =  fetch_by_doi("doi:#{doi}", {}, true)
    end
    collection_params = select_params(:collection_registrant, :collection_doi, :proxy_path)
    collection_id = iiif_collection_url(collection_params)
    collection = Iiif::Collection.new(collection_id, @document, child_service, self)
    render json: collection.as_json(include: [:items, :metadata, :context]).compact
  end

  def cors_headers
    # CORS support: Any site should be able to do a cross-domain info request
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Content-Type'] = 'application/ld+json'
    expires_in(1.day, public: true)
  end

  # return a hash subset of the request params
  def select_params(*keys)
    keys.map { |k| [k, params[k]]}.to_h.compact
  end

  # shims from Blacklight 6 controller fetch to BL 7 search service
  def search_service(user_params = {})
    search_service_class.new(config: blacklight_config, user_params: user_params)
  end
end