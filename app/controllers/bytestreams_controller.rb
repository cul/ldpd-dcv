# -*- encoding : utf-8 -*-
require 'blacklight/catalog'
require 'actionpack/action_caching'

class BytestreamsController < ApplicationController

  include Dcv::NonCatalog
  include Hydra::Controller::ControllerBehavior
  include Dcv::Resources::RelsIntBehavior
  include Cul::Hydra::Resolver
  include Cul::Omniauth::AuthorizingController
  include Cul::Omniauth::RemoteIpAbility
  include Dcv::CatalogHelperBehavior
  include ChildrenHelper
  #caches_action :content, :expires_in => 7.days

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
    id.gsub!(/\:/,'\:')
    p = blacklight_config.default_document_solr_params.merge(extra_controller_params)
    p[:fq] = "identifier_ssim:#{id}"
    solr_response = find(blacklight_config.document_solr_path, p)
    raise Blacklight::Exceptions::InvalidSolrID.new if solr_response.docs.empty?
    document = SolrDocument.new(solr_response.docs.first, solr_response)
    @response, @document = [solr_response, document]
  end

  def index
  	@response, @document = get_solr_response_for_doc_id(params[:catalog_id])
    respond_to do |format|
      format.any do
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
        render json: doc, layout: false
      end
    end
  end

  def content
    @response, @document = get_solr_response_for_doc_id(params[:catalog_id])
    if @document.nil?
      render :status => 404
      return
    end
    return unless authorize_document

    ds_parms = {pid: params[:catalog_id], dsid: params[:bytestream_id]}
    response.headers["Last-Modified"] = Time.now.httpdate
    ds = Cul::Hydra::Fedora.ds_for_opts(ds_parms)
    size = params[:file_size] || params['file_size']
    size ||= ds.dsSize
    label = ds.dsLabel.present? ? ds.dsLabel.split('/').last : 'file'
    if label
      response.headers["Content-Disposition"] = label_to_content_disposition(label,(params['download'].to_s == 'true'))
    end
    ###########################
    if size and size.to_i > 0
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

  # translate a label into a rfc5987 encoded header value
  # see also http://tools.ietf.org/html/rfc5987#section-4.1
  def label_to_content_disposition(label,attachment=false)
    value = attachment ? 'attachment; ' : ''
    value << "filename*=utf-8''#{label.gsub(' ','%20').gsub(',','%2C')}"
    value
  end
end
