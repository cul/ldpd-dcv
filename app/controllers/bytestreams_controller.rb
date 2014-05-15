# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class BytestreamsController < ApplicationController

  include Blacklight::Catalog
  include Hydra::Controller::ControllerBehavior
  include Cul::Scv::Hydra::Resolver
  include Dcv::CatalogHelperBehavior
  include ChildrenHelper
  caches_action :content, :expires_in => 7.days

  respond_to :json

  configure_blacklight do |config|
    config.default_solr_params = {
      :qt => 'search',
      :rows => 12
    }
    config[:unique_key] = :id
    config.index.title_field = solr_name('title_display', :displayable, type: :string)
  end

  def get_solr_response_for_app_id(id=nil, extra_controller_params={})
    id ||= params[:id]
    p = blacklight_config.default_document_solr_params.merge(extra_controller_params)
    p[:fq] = "identifier_ssim:#{(id)}"
    solr_response = find(blacklight_config.document_solr_path, p)
    raise Blacklight::Exceptions::InvalidSolrID.new if solr_response.docs.empty?
    document = SolrDocument.new(solr_response.docs.first, solr_response)
    @response, @document = [solr_response, document]
  end

  def index
  	@response, @document = get_solr_response_for_doc_id(params[:catalog_id])
    respond_to do |format|
      format.any do 
        opts = {}
        opts[:per_page] = params.fetch('per_page', '10')
        opts[:page] = params.fetch('page', '0')
        render json: resources_for_document, layout: false
      end
    end
  end

  def show
  	@response, @document = get_solr_response_for_doc_id(params[:catalog_id])
  	doc = resources_for_document.select {|x| x[:id].split('/')[-1] == params[:id]}
  	doc = doc.first || {}
    respond_to do |format|
      format.any do 
        opts = {}
        opts[:per_page] = params.fetch('per_page', '10')
        opts[:page] = params.fetch('page', '0')
        render json: doc, layout: false
      end
    end
  end

  def content
    @response, @document = get_solr_response_for_doc_id(params[:catalog_id])
    if @document.nil?
      render :status => 401
    end
    ds_parms = {pid: params[:catalog_id], dsid: params[:id]}
    response.headers["Last-Modified"] = Time.now.to_s
    puts ds_parms.inspect()
    ds = Cul::Scv::Fedora.ds_for_opts(ds_parms)
    size = params[:file_size] || params['file_size']
    size ||= ds.dsSize
    unless size and size.to_i > 0
      response.headers["Transfer-Encoding"] = ["chunked"]
    else
      response.headers["Content-Length"] = [size]
    end
    response.headers["Content-Type"] = ds.mimeType

    self.response_body = Enumerator.new do |blk|
      repo = ActiveFedora::Base.connection_for_pid(ds_parms[:pid])
      repo.datastream_dissemination(ds_parms) do |res|
        res.read_body do |seg|
          blk << seg
        end
      end
    end
  end

  def resources_for_document
    model = @document['active_fedora_model_ssi']
    if model == 'GenericResource'
      streams = JSON.load(@document['rels_int_profile_tesim'][0])
      results = []
      streams.each do |k,v|
      	next unless v["format_of"] and v["format_of"].first =~ /content$/
      	title = k.split('/')[-1]
      	id = k
      	mime_type = v['format'].first
      	next if mime_type =~ /jp2$/
        width = v['exif_image_width'].first.to_i
        length = v['exif_image_length'].first.to_i
        size = (v['extent'] || []).first.to_i
        url = url_for_content(id, mime_type)
        results << {
          id: id, title: title, mime_type: mime_type, length: length,
          width: width, size: size, url: url}
      end
      return results

    else
      return []
    end
  end

  def url_for_content(key, mime)
    parts = key.split('/')
    ext = mime.split('/')[-1].downcase
    bytestream_content_url(catalog_id: parts[1], id: parts[2], format: ext)
  end
end