# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class Resolve::BytestreamsController < ApplicationController

  include Dcv::NonCatalog
  include Dcv::Resources::RelsIntBehavior
  include Dcv::Resources::LegacyIdBehavior
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
    config.index.title_field = 'title_display_ssm'
  end

  def get_solr_response_for_app_id(id=nil, extra_controller_params={})
    id ||= params[:id]
    p = blacklight_config.default_document_solr_params.merge(extra_controller_params)
    id.sub!(/apt\:\/columbia/,'apt://columbia') # TOTAL HACK
    id.gsub!(':','\:')
    id.gsub!('/','\/')
    p[:fq] = "dc_identifier_ssim:#{(id)}"
    solr_response = find(blacklight_config.document_solr_path, p)
    raise Blacklight::Exceptions::RecordNotFound.new if solr_response.docs.empty?
    document = SolrDocument.new(solr_response.docs.first, solr_response)
    @response, @document = [solr_response, document]
  end

  def index
  	@response, @document = get_solr_response_for_app_id(params[:catalog_id])
    render json: resources_for_document, layout: false
  end

  def show
  	@response, @document = get_solr_response_for_app_id(params[:catalog_id])
  	doc = resources_for_document.select {|x| x[:id].split('/')[-1] == params[:id]}
  	doc = doc.first || {}
    render json: doc, layout: false
  end

  def content
    @response, @document = get_solr_response_for_app_id(params[:catalog_id])
    if @document.nil?
      render :status => 401
    end
    ds_parms = {pid: @document[:id], dsid: params[:bytestream_id]}
    response.headers["Last-Modified"] = Time.now.to_s
    ds = Cul::Hydra::Fedora.ds_for_opts(ds_parms)
    size = params[:file_size] || params['file_size']
    size ||= ds.dsSize

    ###########################
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
    ###########################
    # TODO: Eventually use new Rails streaming method
#    if size and size.to_i > 0
#			response.headers["Content-Length"] = size
#		end
#    bytes = 0
#    repo = ActiveFedora::Base.connection_for_pid(ds_parms[:pid])
#    repo.datastream_dissemination(ds_parms) do |res|
#			begin
#				res.read_body do |seg|
#					response.stream.write seg
#					bytes += seg.length
#				end
#			ensure
#				response.stream.close
#			end
#		end
		###########################

  end

end
